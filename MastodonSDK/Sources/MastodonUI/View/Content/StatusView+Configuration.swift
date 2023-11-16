//
//  StatusView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-12.
//

import UIKit
import Combine
import CoreDataStack
import MastodonSDK
import MastodonCore
import MastodonLocalization
import MastodonMeta
import Meta
import NaturalLanguage

extension StatusView {
    
    static let statusFilterWorkingQueue = DispatchQueue(label: "StatusFilterWorkingQueue")
    
    public func configure(feed: FeedItem) {
        guard let status = feed.status else {
            assertionFailure()
            return
        }
        configure(status: status)
    }
}

extension StatusView {

    public func configure(status: Mastodon.Entity.Status, statusEdit: Mastodon.Entity.StatusEdit) {
//        viewModel.objects.insert(status)
//        if let reblog = status.reblog {
//            viewModel.objects.insert(status)
//        }

        configureHeader(status: status)
        let author = (status.reblog ?? status).account
        configureAuthor(author: author)
//        let timestamp = (status.reblog ?? status).publisher(for: \.createdAt)
        configureTimestamp(timestamp: (status.reblog ?? status).createdAt)
        configureApplicationName(status.application?.name)
        configureMedia(status: status)
        configurePollHistory(statusEdit: statusEdit)
        configureCard(status: status)
        configureToolbar(status: status)
        configureFilter(status: status)
        configureContent(statusEdit: statusEdit, status: status)
        configureMedia(status: statusEdit)
        actionToolbarAdaptiveMarginContainerView.isHidden = true
        authorView.menuButton.isHidden = true
        headerAdaptiveMarginContainerView.isHidden = true
        viewModel.isSensitiveToggled = true
        viewModel.isContentReveal = true
    }

    public func configure(status: Mastodon.Entity.Status) {
        configureHeader(status: status)
        let author = (status.reblog ?? status).account
        configureAuthor(author: author)
        let timestamp = (status.reblog ?? status).createdAt
        configureTimestamp(timestamp: timestamp)
        configureApplicationName(status.application?.name)
        configureContent(status: status)
        configureMedia(status: status)
        configurePoll(status: status)
        configureCard(status: status)
        configureToolbar(status: status)
        configureFilter(status: status)
        viewModel.originalStatus = status

        viewModel.$translation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] translation in
                self?.configureTranslated(status: status)
            }
            .store(in: &disposeBag)
    }
}

extension StatusView {
    private func configureHeader(status: Mastodon.Entity.Status) {
        if let _ = status.reblog {
            let name = status.account.displayName
            let emojis = status.account.emojis ?? []
            
            viewModel.header = {
                let text = L10n.Common.Controls.Status.userReblogged(status.account.displayNameWithFallback)
                let content = MastodonContent(content: text, emojis: emojis.asDictionary)
                do {
                    let metaContent = try MastodonMetaContent.convert(document: content)
                    return .repost(info: .init(header: metaContent))
                } catch {
                    let metaContent = PlaintextMetaContent(string: name)
                    return .repost(info: .init(header: metaContent))
                }
            }()

        } else if let _ = status.inReplyToID,
                  let inReplyToAccountID = status.inReplyToAccountID
        {
            func createHeader(
                name: String?,
                emojis: MastodonContent.Emojis?
            ) -> ViewModel.Header {
                let fallbackMetaContent = PlaintextMetaContent(string: L10n.Common.Controls.Status.userRepliedTo("-"))
                let fallbackReplyHeader = ViewModel.Header.reply(info: .init(header: fallbackMetaContent))
                guard let name = name,
                      let emojis = emojis
                else {
                    return fallbackReplyHeader
                }
                
                let content = MastodonContent(content: L10n.Common.Controls.Status.userRepliedTo(name), emojis: emojis)
                guard let metaContent = try? MastodonMetaContent.convert(document: content) else {
                    return fallbackReplyHeader
                }
                let header = ViewModel.Header.reply(info: .init(header: metaContent))
                return header
            }

            if let inReplyToID = status.inReplyToID {
                // A. replyTo status exist
                if let authenticationBox = viewModel.authContext?.mastodonAuthenticationBox {
                    Task {
                        if let replyTo = try? await Mastodon.API.Statuses.status(
                            session: .shared,
                            domain: authenticationBox.domain,
                            statusID: inReplyToID,
                            authorization: authenticationBox.userAuthorization
                        ).singleOutput().value {
                            let header = createHeader(name: replyTo.account.displayNameWithFallback, emojis: replyTo.account.emojis?.asDictionary ?? [:])
                            viewModel.header = header
                        }
                    }
                }
            } else {
                // B. replyTo status not exist
                
//                let request = MastodonUser.sortedFetchRequest
//                request.predicate = MastodonUser.predicate(domain: status.domain, id: inReplyToAccountID)
//                if let user = status.managedObjectContext?.safeFetch(request).first {
//                    // B1. replyTo user exist
//                    let header = createHeader(name: user.displayNameWithFallback, emojis: user.emojis.asDictionary)
//                    viewModel.header = header
//                } else {
                    // B2. replyTo user not exist
                    let header = createHeader(name: nil, emojis: nil)
                    viewModel.header = header
                    
                    if let authenticationBox = viewModel.authContext?.mastodonAuthenticationBox {
                        Just(inReplyToAccountID)
                            .asyncMap { userID in
                                return try await Mastodon.API.Account.accountInfo(
                                    session: .shared,
                                    domain: authenticationBox.domain,
                                    userID: userID,
                                    authorization: authenticationBox.userAuthorization
                                ).singleOutput()
                            }
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                // do nothing
                            } receiveValue: { [weak self] response in
                                guard let self = self else { return }
                                let user = response.value
                                let header = createHeader(name: user.displayNameWithFallback, emojis: user.emojiMeta)
                                self.viewModel.header = header
                            }
                            .store(in: &disposeBag)
                    }   // end if let
//                }   // end else B2.
            }   // end else B.
            
        } else {
            viewModel.header = .none
        }
    }
    
    public func configureAuthor(author: Mastodon.Entity.Account) {
        // author avatar
        viewModel.authorAvatarImageURL = author.avatarImageURL()
        let emojis = author.emojis?.asDictionary ?? [:]
        
        // author name
        viewModel.authorName = {
            do {
                let content = MastodonContent(content: author.displayNameWithFallback, emojis: emojis)
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return PlaintextMetaContent(string: author.displayNameWithFallback)
            }
        }()
        
        // author username
        viewModel.authorUsername = author.acct

        // locked
        viewModel.locked = author.locked

        // isMuting, isBlocking, Following
        Task {
            guard let auth = viewModel.authContext?.mastodonAuthenticationBox else { return }
            if let relationship = try? await Mastodon.API.Account.relationships(
                session: .shared,
                domain: auth.domain,
                query: .init(ids: [author.id]),
                authorization: auth.userAuthorization
            ).singleOutput().value {
                guard let rel = relationship.first else { return }
                DispatchQueue.main.async { [self] in
                    viewModel.isMuting = rel.muting ?? false
                    viewModel.isBlocking = rel.blocking
                    viewModel.isFollowed = rel.followedBy
                }
            }
        }

        // isMyself
        viewModel.isMyself = {
            guard let authContext = viewModel.authContext else { return false }
            return authContext.mastodonAuthenticationBox.domain == author.domain && authContext.mastodonAuthenticationBox.userID == author.id
        }()

    }
    
    private func configureTimestamp(timestamp: Date) {
        // timestamp
        viewModel.timestampFormatter = { (date: Date, isEdited: Bool) in
            if isEdited {
                return L10n.Common.Controls.Status.editedAtTimestampPrefix(date.localizedSlowedTimeAgoSinceNow)
            }
            return date.localizedSlowedTimeAgoSinceNow
        }
        viewModel.timestamp = timestamp
    }

    private func configureApplicationName(_ applicationName: String?) {
        viewModel.applicationName = applicationName
    }
    
    public func revertTranslation() {
        guard let originalStatus = viewModel.originalStatus else { return }
        
        viewModel.translation = nil
        configure(status: originalStatus)
    }
    
    func configureTranslated(status: Mastodon.Entity.Status) {
        guard let translation = viewModel.translation,
              let translatedContent = translation.content else {
            viewModel.isCurrentlyTranslating = false
            return
        }

        // content
        do {
            let content = MastodonContent(content: translatedContent, emojis: status.emojis?.asDictionary ?? [:])
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.content = metaContent
            viewModel.isCurrentlyTranslating = false
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = PlaintextMetaContent(string: "")
        }
    }

    private func configureContent(statusEdit: Mastodon.Entity.StatusEdit, status: Mastodon.Entity.Status) {
        statusEdit.spoilerText.map {
            viewModel.spoilerContent = PlaintextMetaContent(string: $0)
        }
        
        // language
        viewModel.language = (status.reblog ?? status).language
        // content
        do {
            let content = MastodonContent(content: statusEdit.content, emojis: statusEdit.emojis?.asDictionary ?? [:])
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.content = metaContent
            viewModel.isCurrentlyTranslating = false
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = PlaintextMetaContent(string: "")
        }
    }

    private func configureContent(status: Mastodon.Entity.Status) {
        guard viewModel.translation == nil else {
            return configureTranslated(status: status)
        }
        
        let status = status.reblog ?? status
        
        // spoilerText
        if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
            do {
                let content = MastodonContent(content: spoilerText, emojis: status.emojis?.asDictionary ?? [:])
                let metaContent = try MastodonMetaContent.convert(document: content)
                viewModel.spoilerContent = metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                viewModel.spoilerContent = PlaintextMetaContent(string: "")
            }
        } else {
            viewModel.spoilerContent = nil
        }
        // language
        viewModel.language = (status.reblog ?? status).language
        // content
        do {
            let content = MastodonContent(content: status.content ?? "", emojis: status.emojis?.asDictionary ?? [:])
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.content = metaContent
            viewModel.isCurrentlyTranslating = false
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = PlaintextMetaContent(string: "")
        }
        // visibility
        viewModel.visibility = status.mastodonVisibility

        // sensitive
        viewModel.isContentSensitive = status.sensitive == true
        viewModel.isSensitiveToggled = status.sensitiveToggled

    }
    
    private func configureMedia(status: Mastodon.Entity.Status) {
        let status = status.reblog ?? status
        
        viewModel.isMediaSensitive = status.sensitive == true
        
        let configurations = MediaView.configuration(status: status)
        viewModel.mediaViewConfigurations = configurations
    }
    
    private func configureMedia(status: Mastodon.Entity.StatusEdit) {
        viewModel.isMediaSensitive = status.sensitive
        
        let configurations = MediaView.configuration(status: status)
        viewModel.mediaViewConfigurations = configurations
    }
    
    private func configurePollHistory(statusEdit: Mastodon.Entity.StatusEdit) {
        guard let poll = statusEdit.poll else { return }

        let pollItems = poll.options.map { PollItem.history(option: $0) }
        self.viewModel.pollItems = pollItems
        pollStatusStackView.isHidden = true

        var _snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
        _snapshot.appendSections([.main])
        _snapshot.appendItems(pollItems, toSection: .main)
        pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(_snapshot)
    }

    private func configurePoll(status: Mastodon.Entity.Status) {
        let status = status.reblog ?? status
        
//        if let poll = status.poll {
//            viewModel.objects.insert(poll)
//        }

        // pollItems
        viewModel.pollItems = {
            guard let poll = status.poll else {
                return []
            }
            
//            let options = poll.options.sorted(by: { $0. < $1.index })
//            let items: [PollItem] = options.map { .option(record: .init(objectID: $0.objectID)) }
            return poll.options.map { .option(record: $0, poll: poll) }
        }()
        // isVoteButtonEnabled
        if let poll = status.poll {
            viewModel.isVoteButtonEnabled = {
//                guard let poll = status.poll else { return false }
//                let options = poll.options
//                return options.contains(where: { $0.isSelected })
                return poll.voted == false
            }()
        }

        // isVotable
        if let poll = status.poll {
            viewModel.isVotable = poll.voted == false && !poll.expired
        }
        
        // votesCount
        viewModel.voteCount = status.poll?.votesCount ?? 0
        
        // voterCount
        viewModel.voterCount = status.poll?.votersCount

        // expireAt
        viewModel.expireAt = status.poll?.expiresAt

        // expired
        viewModel.expired = status.poll?.expired == true

        // isVoting
        viewModel.isVoting = status.poll?.isVoting == true
    }

    private func configureCard(status: Mastodon.Entity.Status) {
        let status = status.reblog ?? status
        if viewModel.mediaViewConfigurations.isEmpty {
            viewModel.card = status.card
        } else {
            viewModel.card = nil
        }
    }
    
    private func configureToolbar(status: Mastodon.Entity.Status) {
        let status = status.reblog ?? status

        viewModel.replyCount = status.repliesCount ?? 0
        
        viewModel.reblogCount = status.reblogsCount
        
        viewModel.favoriteCount = status.favouritesCount
        
        viewModel.editedAt = status.editedAt

        // relationship
        viewModel.isReblog = status.reblogged == true
        viewModel.isFavorite = status.favourited == true
        viewModel.isBookmark = status.bookmarked == true
    }
    
    private func configureFilter(status: Mastodon.Entity.Status) {
        let status = status.reblog ?? status
        
        guard let content = status.content?.lowercased() else { return }
        
        Publishers.CombineLatest(
            viewModel.$activeFilters,
            viewModel.$filterContext
        )
        .receive(on: StatusView.statusFilterWorkingQueue)
        .map { filters, filterContext in
            var wordFilters: [Mastodon.Entity.Filter] = []
            var nonWordFilters: [Mastodon.Entity.Filter] = []
            for filter in filters {
                guard filter.context.contains(where: { $0 == filterContext }) else { continue }
                if filter.wholeWord {
                    wordFilters.append(filter)
                } else {
                    nonWordFilters.append(filter)
                }
            }

            var needsFilter = false
            for filter in nonWordFilters {
                guard content.contains(filter.phrase.lowercased()) else { continue }
                needsFilter = true
                break
            }

            if needsFilter {
                return true
            }

            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = content
            let phraseWords = wordFilters.map { $0.phrase.lowercased() }
            tokenizer.enumerateTokens(in: content.startIndex..<content.endIndex) { range, _ in
                let word = String(content[range])
                if phraseWords.contains(word) {
                    needsFilter = true
                    return false
                } else {
                    return true
                }
            }

            return needsFilter
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.isFiltered, on: viewModel)
        .store(in: &disposeBag)
    }

}
