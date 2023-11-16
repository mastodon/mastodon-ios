//
//  NotificationView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import MastodonUI
import MetaTextKit
import MastodonMeta
import Meta
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK

extension NotificationView {
    public func configure(feed: FeedItem) {
        guard let notification = feed.notification else {
            assertionFailure()
            return
        }
        
        configure(notification: notification)
    }
}

extension NotificationView {
    public func configure(notification: Mastodon.Entity.Notification) {
        configureAuthor(notification: notification)

        switch notification.type {
        case .follow:
            setAuthorContainerBottomPaddingViewDisplay()
        case .followRequest:
            setFollowRequestAdaptiveMarginContainerViewDisplay()
        case .mention, .status:
            if let status = notification.status {
                statusView.configure(status: status)
                setStatusViewDisplay()
            }
        case .reblog, .favourite, .poll:
            if let status = notification.status {
                quoteStatusView.configure(status: status)
                setQuoteStatusViewDisplay()
            }
        case ._other:
            setAuthorContainerBottomPaddingViewDisplay()
            assertionFailure()
        }
        
    }
}

extension NotificationView {
    private func configureAuthor(notification: Mastodon.Entity.Notification) {
        let author = notification.account
        // author avatar
        viewModel.authorAvatarImageURL = author.avatarImageURL()
        
        // author name
        viewModel.authorName = {
            do {
                let content = MastodonContent(content: author.displayNameWithFallback, emojis: author.emojis?.asDictionary ?? [:])
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return PlaintextMetaContent(string: author.displayNameWithFallback)
            }
        }()
        
        // author username
        viewModel.authorUsername = author.acct
        
        // timestamp
        viewModel.timestamp = notification.createdAt

        viewModel.visibility = notification.status?.mastodonVisibility ?? ._other("")

        // notification type indicator
        self.viewModel.type = notification.type

        func createMetaContent(text: String, emojis: MastodonContent.Emojis) -> MetaContent {
            let content = MastodonContent(content: text, emojis: emojis)
            guard let metaContent = try? MastodonMetaContent.convert(document: content) else {
                return PlaintextMetaContent(string: text)
            }
            return metaContent
        }

        // TODO: fix the i18n. The subject should assert place at the string beginning
        guard let type = viewModel.type else { return }
        
        switch type {
        case .follow:
            self.viewModel.notificationIndicatorText = createMetaContent(
                text: L10n.Scene.Notification.NotificationDescription.followedYou,
                emojis: author.emojis?.asDictionary ?? [:]
            )
        case .followRequest:
            self.viewModel.notificationIndicatorText = createMetaContent(
                text: L10n.Scene.Notification.NotificationDescription.requestToFollowYou,
                emojis: author.emojis?.asDictionary ?? [:]
            )
        case .mention:
            self.viewModel.notificationIndicatorText = createMetaContent(
                text: L10n.Scene.Notification.NotificationDescription.mentionedYou,
                emojis: author.emojis?.asDictionary ?? [:]
            )
        case .reblog:
            self.viewModel.notificationIndicatorText = createMetaContent(
                text: L10n.Scene.Notification.NotificationDescription.rebloggedYourPost,
                emojis: author.emojis?.asDictionary ?? [:]
            )
        case .favourite:
            self.viewModel.notificationIndicatorText = createMetaContent(
                text: L10n.Scene.Notification.NotificationDescription.favoritedYourPost,
                emojis: author.emojis?.asDictionary ?? [:]
            )
        case .poll:
            self.viewModel.notificationIndicatorText = createMetaContent(
                text: L10n.Scene.Notification.NotificationDescription.pollHasEnded,
                emojis: author.emojis?.asDictionary ?? [:]
            )
        case .status:
            self.viewModel.notificationIndicatorText = createMetaContent(
                text: .empty,
                emojis: author.emojis?.asDictionary ?? [:]
            )
        case ._other:
            self.viewModel.notificationIndicatorText = nil
        }
        
        guard let authContext = viewModel.authContext else { return }

        Task {
            guard let context = viewModel.context else { return }
            if let relationship = try await context.apiService.relationship(records: [author], authenticationBox: authContext.mastodonAuthenticationBox).value.first {
                
                viewModel.isMuting = relationship.muting == true
                viewModel.isBlocking = relationship.blockedBy == true // OR: blocking ???
                viewModel.isFollowed = relationship.followedBy
            }
            
//            let pendingFollowRequests = try await context.apiService.pendingFollowRequest(userID: notification.account.id, authenticationBox: authContext.mastodonAuthenticationBox).value
            
//            pendingFollowRequests
        }

        // isMyself
        viewModel.isMyself = (author.domain == authContext.mastodonAuthenticationBox.domain) && (author.id == authContext.mastodonAuthenticationBox.userID)

        #warning("re-implemented the two below")
        // follow request state
//        notification.publisher(for: \.followRequestState)
//            .assign(to: \.followRequestState, on: viewModel)
//            .store(in: &disposeBag)
        
//        notification.publisher(for: \.transientFollowRequestState)
//            .assign(to: \.transientFollowRequestState, on: viewModel)
//            .store(in: &disposeBag)

        // Following
//        author.publisher(for: \.followingBy)
//            .map { [weak viewModel] followingBy in
//                guard let viewModel = viewModel else { return false }
//                guard let authContext = viewModel.authContext else { return false }
//                return followingBy.contains(where: {
//                    $0.id == authContext.mastodonAuthenticationBox.userID && $0.domain == authContext.mastodonAuthenticationBox.domain
//                })
//            }
//            .assign(to: \.isFollowed, on: viewModel)
//            .store(in: &disposeBag)

    }
}
