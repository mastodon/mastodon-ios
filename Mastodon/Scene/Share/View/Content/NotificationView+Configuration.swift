//
//  NotificationView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import MastodonUI
import CoreDataStack
import MetaTextKit
import MastodonMeta
import Meta
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK

extension NotificationView {
    public func configure(feed: MastodonFeed) {
        guard  let notification = feed.notification else {
            assertionFailure()
            return
        }

        MastodonNotification.fromEntity(
            notification,
            relationship: feed.relationship,
            domain: viewModel.authContext?.mastodonAuthenticationBox.domain ?? ""
        ).map(configure(notification:))
    }
}

extension NotificationView {
    public func configure(notification: MastodonNotification) {
        configureAuthor(notification: notification)

        switch notification.entity.type {
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
    private func configureAuthor(notification: MastodonNotification) {
        let author = notification.account

        // author avatar
        viewModel.authorAvatarImageURL = author.avatarImageURL()

        // author name
        do {
            let content = MastodonContent(content: author.displayNameWithFallback, emojis: author.emojis.asDictionary)
            viewModel.authorName = try MastodonMetaContent.convert(document: content)
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.authorName = PlaintextMetaContent(string: author.displayNameWithFallback)
        }

        viewModel.authorUsername = author.acct
        viewModel.timestamp = notification.entity.createdAt

        viewModel.visibility = notification.entity.status?.mastodonVisibility ?? ._other("")

        // notification type indicator
        if let type = MastodonNotificationType(rawValue: notification.entity.type.rawValue) {
            self.viewModel.type = type

            // TODO: fix the i18n. The subject should assert place at the string beginning
            func createMetaContent(text: String, emojis: MastodonContent.Emojis) -> MetaContent {
                let content = MastodonContent(content: text, emojis: emojis)
                guard let metaContent = try? MastodonMetaContent.convert(document: content) else {
                    return PlaintextMetaContent(string: text)
                }
                return metaContent
            }
            
            switch type {
            case .follow:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.followedYou,
                    emojis: author.emojis.asDictionary
                )
            case .followRequest:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.requestToFollowYou,
                    emojis: author.emojis.asDictionary
                )
            case .mention:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.mentionedYou,
                    emojis: author.emojis.asDictionary
                )
            case .reblog:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.rebloggedYourPost,
                    emojis: author.emojis.asDictionary
                )
            case .favourite:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.favoritedYourPost,
                    emojis: author.emojis.asDictionary
                )
            case .poll:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.pollHasEnded,
                    emojis: author.emojis.asDictionary
                )
            case .status:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: .empty,
                    emojis: author.emojis.asDictionary
                )
            case ._other:
                self.viewModel.notificationIndicatorText = nil
            }
        } else {
            self.viewModel.notificationIndicatorText = nil
        }
        
        if let me = viewModel.authContext?.mastodonAuthenticationBox.authentication.account() {
            viewModel.isMyself = (author == me)
            
            if let relationship = notification.relationship {
                viewModel.isMuting = relationship.muting
                viewModel.isBlocking = relationship.blocking || relationship.domainBlocking
                viewModel.isFollowed = relationship.following
            } else {
                viewModel.isMuting = false
                viewModel.isBlocking = false
                viewModel.isFollowed = false
            }
        }

        viewModel.followRequestState = notification.followRequestState
        viewModel.transientFollowRequestState = notification.transientFollowRequestState
    }
}
