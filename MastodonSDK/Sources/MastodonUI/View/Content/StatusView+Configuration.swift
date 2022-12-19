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
    
    public func configure(feed: Feed) {
        switch feed.kind {
        case .home:
            guard let status = feed.status else {
                assertionFailure()
                return
            }
            configure(status: status)
        case .notificationAll:
            assertionFailure("TODO")
        case .notificationMentions:
            assertionFailure("TODO")
        case .none:
            break
        }
        
    }
}

extension StatusView {
    public func configure(status: Status) {
        viewModel.objects.insert(status)
        if let reblog = status.reblog {
            viewModel.objects.insert(reblog)
        }

        configureHeader(status: status)
        let author = (status.reblog ?? status).author
        configureAuthor(author: author)
        let timestamp = (status.reblog ?? status).publisher(for: \.createdAt)
        configureTimestamp(timestamp: timestamp.eraseToAnyPublisher())
        configureContent(status: status)
        configureMedia(status: status)
        configurePoll(status: status)
        configureCard(status: status)
        configureToolbar(status: status)
        configureFilter(status: status)
        viewModel.originalStatus = status
        [
            status.publisher(for: \.translatedContent),
            status.reblog?.publisher(for: \.translatedContent)
        ].compactMap { $0 }
            .last?
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.configureTranslated(status: status)
            }
            .store(in: &disposeBag)
    }
}

extension StatusView {
    private func configureHeader(status: Status) {
        if let _ = status.reblog {
            Publishers.CombineLatest(
                status.author.publisher(for: \.displayName),
                status.author.publisher(for: \.emojis)
            )
            .map { name, emojis -> StatusView.ViewModel.Header in
                let text = L10n.Common.Controls.Status.userReblogged(status.author.displayNameWithFallback)
                let content = MastodonContent(content: text, emojis: emojis.asDictionary)
                do {
                    let metaContent = try MastodonMetaContent.convert(document: content)
                    return .repost(info: .init(header: metaContent))
                } catch {
                    let metaContent = PlaintextMetaContent(string: name)
                    return .repost(info: .init(header: metaContent))
                }
                
            }
            .assign(to: \.header, on: viewModel)
            .store(in: &disposeBag)
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
                        
            if let replyTo = status.replyTo {
                // A. replyTo status exist
                let header = createHeader(name: replyTo.author.displayNameWithFallback, emojis: replyTo.author.emojis.asDictionary)
                viewModel.header = header
            } else {
                // B. replyTo status not exist
                
                let request = MastodonUser.sortedFetchRequest
                request.predicate = MastodonUser.predicate(domain: status.domain, id: inReplyToAccountID)
                if let user = status.managedObjectContext?.safeFetch(request).first {
                    // B1. replyTo user exist
                    let header = createHeader(name: user.displayNameWithFallback, emojis: user.emojis.asDictionary)
                    viewModel.header = header
                } else {
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
                }   // end else B2.
            }   // end else B.
            
        } else {
            viewModel.header = .none
        }
    }
    
    public func configureAuthor(author: MastodonUser) {
        // author avatar
        Publishers.CombineLatest(
            author.publisher(for: \.avatar),
            UserDefaults.shared.publisher(for: \.preferredStaticAvatar)
        )
        .map { _ in author.avatarImageURL() }
        .assign(to: \.authorAvatarImageURL, on: viewModel)
        .store(in: &disposeBag)
        // author name
        Publishers.CombineLatest(
            author.publisher(for: \.displayName),
            author.publisher(for: \.emojis)
        )
        .map { _, emojis in
            do {
                let content = MastodonContent(content: author.displayNameWithFallback, emojis: emojis.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return PlaintextMetaContent(string: author.displayNameWithFallback)
            }
        }
        .assign(to: \.authorName, on: viewModel)
        .store(in: &disposeBag)
        // author username
        author.publisher(for: \.acct)
            .map { $0 as String? }
            .assign(to: \.authorUsername, on: viewModel)
            .store(in: &disposeBag)
        // locked
        author.publisher(for: \.locked)
            .assign(to: \.locked, on: viewModel)
            .store(in: &disposeBag)
        // isMuting
        author.publisher(for: \.mutingBy)
            .map { [weak viewModel] mutingBy in
                guard let viewModel = viewModel else { return false }
                guard let authContext = viewModel.authContext else { return false }
                return mutingBy.contains(where: {
                    $0.id == authContext.mastodonAuthenticationBox.userID && $0.domain == authContext.mastodonAuthenticationBox.domain
                })
            }
            .assign(to: \.isMuting, on: viewModel)
            .store(in: &disposeBag)
        // isBlocking
        author.publisher(for: \.blockingBy)
            .map { [weak viewModel] blockingBy in
                guard let viewModel = viewModel else { return false }
                guard let authContext = viewModel.authContext else { return false }
                return blockingBy.contains(where: {
                    $0.id == authContext.mastodonAuthenticationBox.userID && $0.domain == authContext.mastodonAuthenticationBox.domain
                })
            }
            .assign(to: \.isBlocking, on: viewModel)
            .store(in: &disposeBag)
        // isMyself
        Publishers.CombineLatest(
            author.publisher(for: \.domain),
            author.publisher(for: \.id)
        )
        .map { [weak viewModel] domain, id in
            guard let viewModel = viewModel else { return false }
            guard let authContext = viewModel.authContext else { return false }
            return authContext.mastodonAuthenticationBox.domain == domain && authContext.mastodonAuthenticationBox.userID == id
        }
        .assign(to: \.isMyself, on: viewModel)
        .store(in: &disposeBag)
    }
    
    private func configureTimestamp(timestamp: AnyPublisher<Date, Never>) {
        // timestamp
        viewModel.timestampFormatter = { (date: Date) in
            date.localizedSlowedTimeAgoSinceNow
        }
        timestamp
            .map { $0 as Date? }
            .assign(to: \.timestamp, on: viewModel)
            .store(in: &disposeBag)
    }
    
    func revertTranslation() {
        guard let originalStatus = viewModel.originalStatus else { return }
        viewModel.translatedFromLanguage = nil
        viewModel.translatedUsingProvider = nil
        originalStatus.reblog?.update(translatedContent: nil)
        originalStatus.update(translatedContent: nil)
        configure(status: originalStatus)
    }
    
    func configureTranslated(status: Status) {
        let translatedContent: Status.TranslatedContent? = {
            if let translatedContent = status.reblog?.translatedContent {
                return translatedContent
            }
            return status.translatedContent

        }()
        
        guard
            let translatedContent = translatedContent
        else {
            viewModel.isCurrentlyTranslating = false
            return
        }

        // content
        do {
            let content = MastodonContent(content: translatedContent.content, emojis: status.emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.content = metaContent
            viewModel.translatedFromLanguage = status.reblog?.language ?? status.language
            viewModel.translatedUsingProvider = status.reblog?.translatedContent?.provider ?? status.translatedContent?.provider
            viewModel.isCurrentlyTranslating = false
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = PlaintextMetaContent(string: "")
        }
    }
    
    private func configureContent(status: Status) {
        guard status.translatedContent == nil else {
            return configureTranslated(status: status)
        }
        
        let status = status.reblog ?? status
        
        // spoilerText
        if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
            do {
                let content = MastodonContent(content: spoilerText, emojis: status.emojis.asDictionary)
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
            let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.content = metaContent
            viewModel.translatedFromLanguage = nil
            viewModel.isCurrentlyTranslating = false
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = PlaintextMetaContent(string: "")
        }
        // visibility
        status.publisher(for: \.visibilityRaw)
            .compactMap { MastodonVisibility(rawValue: $0) }
            .assign(to: \.visibility, on: viewModel)
            .store(in: &disposeBag)
        // sensitive
        viewModel.isContentSensitive = status.isContentSensitive
        status.publisher(for: \.isSensitiveToggled)
            .assign(to: \.isSensitiveToggled, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureMedia(status: Status) {
        let status = status.reblog ?? status
        
        viewModel.isMediaSensitive = status.isMediaSensitive
        
        let configurations = MediaView.configuration(status: status)
        viewModel.mediaViewConfigurations = configurations
    }

    private func configurePoll(status: Status) {
        let status = status.reblog ?? status
        
        if let poll = status.poll {
            viewModel.objects.insert(poll)
        }

        // pollItems
        status.publisher(for: \.poll)
            .sink { [weak self] poll in
                guard let self = self else { return }
                guard let poll = poll else {
                    self.viewModel.pollItems = []
                    return
                }
                
                let options = poll.options.sorted(by: { $0.index < $1.index })
                let items: [PollItem] = options.map { .option(record: .init(objectID: $0.objectID)) }
                self.viewModel.pollItems = items
            }
            .store(in: &disposeBag)
        // isVoteButtonEnabled
        status.poll?.publisher(for: \.updatedAt)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let poll = status.poll else { return }
                let options = poll.options
                let hasSelectedOption = options.contains(where: { $0.isSelected })
                self.viewModel.isVoteButtonEnabled = hasSelectedOption
            }
            .store(in: &disposeBag)
        // isVotable
        if let poll = status.poll {
            Publishers.CombineLatest(
                poll.publisher(for: \.votedBy),
                poll.publisher(for: \.expired)
            )
            .map { [weak viewModel] votedBy, expired in
                guard let viewModel = viewModel else { return false }
                guard let authContext = viewModel.authContext else { return false }
                let domain = authContext.mastodonAuthenticationBox.domain
                let userID = authContext.mastodonAuthenticationBox.userID
                let isVoted = votedBy?.contains(where: { $0.domain == domain && $0.id == userID }) ?? false
                return !isVoted && !expired
            }
            .assign(to: &viewModel.$isVotable)
        }
        // votesCount
        status.poll?.publisher(for: \.votesCount)
            .map { Int($0) }
            .assign(to: \.voteCount, on: viewModel)
            .store(in: &disposeBag)
        // voterCount
        status.poll?.publisher(for: \.votersCount)
            .map { Int($0) }
            .assign(to: \.voterCount, on: viewModel)
            .store(in: &disposeBag)
        // expireAt
        status.poll?.publisher(for: \.expiresAt)
            .assign(to: \.expireAt, on: viewModel)
            .store(in: &disposeBag)
        // expired
        status.poll?.publisher(for: \.expired)
            .assign(to: \.expired, on: viewModel)
            .store(in: &disposeBag)
        // isVoting
        status.poll?.publisher(for: \.isVoting)
            .assign(to: \.isVoting, on: viewModel)
            .store(in: &disposeBag)
    }

    private func configureCard(status: Status) {
        let status = status.reblog ?? status
        if viewModel.mediaViewConfigurations.isEmpty {
            status.publisher(for: \.card)
                .assign(to: \.card, on: viewModel)
                .store(in: &disposeBag)
        } else {
            viewModel.card = nil
        }
    }
    
    private func configureToolbar(status: Status) {
        let status = status.reblog ?? status

        status.publisher(for: \.repliesCount)
            .map(Int.init)
            .assign(to: \.replyCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.reblogsCount)
            .map(Int.init)
            .assign(to: \.reblogCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.favouritesCount)
            .map(Int.init)
            .assign(to: \.favoriteCount, on: viewModel)
            .store(in: &disposeBag)
        
        // relationship
        status.publisher(for: \.rebloggedBy)
            .map { [weak viewModel] rebloggedBy in
                guard let viewModel = viewModel else { return false }
                guard let authContext = viewModel.authContext else { return false }
                return rebloggedBy.contains(where: {
                    $0.id == authContext.mastodonAuthenticationBox.userID && $0.domain == authContext.mastodonAuthenticationBox.domain
                })
            }
            .assign(to: \.isReblog, on: viewModel)
            .store(in: &disposeBag)
        
        status.publisher(for: \.favouritedBy)
            .map { [weak viewModel]favouritedBy in
                guard let viewModel = viewModel else { return false }
                guard let authContext = viewModel.authContext else { return false }
                return favouritedBy.contains(where: {
                    $0.id == authContext.mastodonAuthenticationBox.userID && $0.domain == authContext.mastodonAuthenticationBox.domain
                })
            }
            .assign(to: \.isFavorite, on: viewModel)
            .store(in: &disposeBag)

        status.publisher(for: \.bookmarkedBy)
            .map { [weak viewModel] bookmarkedBy in
                guard let viewModel = viewModel else { return false }
                guard let authContext = viewModel.authContext else { return false }
                return bookmarkedBy.contains(where: {
                    $0.id == authContext.mastodonAuthenticationBox.userID && $0.domain == authContext.mastodonAuthenticationBox.domain
                })
            }
            .assign(to: \.isBookmark, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureFilter(status: Status) {
        let status = status.reblog ?? status
        
        let content = status.content.lowercased()
        
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
