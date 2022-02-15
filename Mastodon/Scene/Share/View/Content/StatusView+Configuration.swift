//
//  StatusView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-12.
//

import UIKit
import Combine
import MastodonUI
import CoreDataStack
import MastodonLocalization
import MastodonMeta
import Meta

extension StatusView {
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
        configureToolbar(status: status)        
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
                    
                    if let authenticationBox = AppContext.shared.authenticationService.activeMastodonAuthenticationBox.value {
                        Just(inReplyToAccountID)
                            .asyncMap { userID in
                                return try await AppContext.shared.apiService.accountInfo(
                                    domain: authenticationBox.domain,
                                    userID: userID,
                                    authorization: authenticationBox.userAuthorization
                                )
                            }
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
        Publishers.CombineLatest(
            viewModel.$userIdentifier,
            author.publisher(for: \.mutingBy)
        )
        .map { userIdentifier, mutingBy in
            guard let userIdentifier = userIdentifier else { return false }
            return mutingBy.contains(where: {
                $0.id == userIdentifier.userID && $0.domain == userIdentifier.domain
            })
        }
        .assign(to: \.isMuting, on: viewModel)
        .store(in: &disposeBag)
        // isBlocking
        Publishers.CombineLatest(
            viewModel.$userIdentifier,
            author.publisher(for: \.blockingBy)
        )
        .map { userIdentifier, blockingBy in
            guard let userIdentifier = userIdentifier else { return false }
            return blockingBy.contains(where: {
                $0.id == userIdentifier.userID && $0.domain == userIdentifier.domain
            })
        }
        .assign(to: \.isBlocking, on: viewModel)
        .store(in: &disposeBag)
        // isMyself
        Publishers.CombineLatest3(
            viewModel.$userIdentifier,
            author.publisher(for: \.domain),
            author.publisher(for: \.id)
        )
        .map { userIdentifier, domain, id in
            guard let userIdentifier = userIdentifier else { return false }
            return userIdentifier.domain == domain
                && userIdentifier.userID == id
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
    
    private func configureContent(status: Status) {
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
        status.publisher(for: \.isContentSensitiveToggled)
            .assign(to: \.isContentSensitiveToggled, on: viewModel)
            .store(in: &disposeBag)

        
//        viewModel.source = status.source
    }
    
    private func configureMedia(status: Status) {
        let status = status.reblog ?? status
        
        viewModel.isMediaSensitive = status.sensitive && !status.attachments.isEmpty        // some servers set media sensitive even empty attachments
        
        let configurations = MediaView.configuration(status: status)
        viewModel.mediaViewConfigurations = configurations
        
        status.publisher(for: \.isMediaSensitiveToggled)
            .assign(to: \.isMediaSensitiveToggled, on: viewModel)
            .store(in: &disposeBag)
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
            Publishers.CombineLatest3(
                poll.publisher(for: \.votedBy),
                poll.publisher(for: \.expired),
                viewModel.$userIdentifier
            )
            .map { votedBy, expired, userIdentifier in
                guard let userIdentifier = userIdentifier else { return false }
                let domain = userIdentifier.domain
                let userID = userIdentifier.userID
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
        Publishers.CombineLatest(
            viewModel.$userIdentifier,
            status.publisher(for: \.rebloggedBy)
        )
        .map { userIdentifier, rebloggedBy in
            guard let userIdentifier = userIdentifier else { return false }
            return rebloggedBy.contains(where: {
                $0.id == userIdentifier.userID && $0.domain == userIdentifier.domain
            })
        }
        .assign(to: \.isReblog, on: viewModel)
        .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            viewModel.$userIdentifier,
            status.publisher(for: \.favouritedBy)
        )
        .map { userIdentifier, favouritedBy in
            guard let userIdentifier = userIdentifier else { return false }
            return favouritedBy.contains(where: {
                $0.id == userIdentifier.userID && $0.domain == userIdentifier.domain
            })
        }
        .assign(to: \.isFavorite, on: viewModel)
        .store(in: &disposeBag)
    }

}
