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
        let configuration = AvatarImageView.Configuration(url: author.avatarImageURL())
        avatarButton.avatarImageView.configure(configuration: configuration)
        avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 12)))

        // author name
        let metaAuthorName: MetaContent
        do {
            let content = MastodonContent(content: author.displayNameWithFallback, emojis: author.emojis.asDictionary)
            metaAuthorName = try MastodonMetaContent.convert(document: content)
        } catch {
            assertionFailure(error.localizedDescription)
            metaAuthorName = PlaintextMetaContent(string: author.displayNameWithFallback)
        }
        authorNameLabel.configure(content: metaAuthorName)

        // username
        let metaUsername = PlaintextMetaContent(string: "@\(author.acct)")
        authorUsernameLabel.configure(content: metaUsername)

        let visibility = notification.entity.status?.mastodonVisibility ?? ._other("")
        visibilityIconImageView.image = visibility.image

        // notification type indicator
        let notificationIndicatorText: MetaContent?
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
                notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.followedYou,
                    emojis: author.emojis.asDictionary
                )
            case .followRequest:
                notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.requestToFollowYou,
                    emojis: author.emojis.asDictionary
                )
            case .mention:
                notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.mentionedYou,
                    emojis: author.emojis.asDictionary
                )
            case .reblog:
                notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.rebloggedYourPost,
                    emojis: author.emojis.asDictionary
                )
            case .favourite:
                notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.favoritedYourPost,
                    emojis: author.emojis.asDictionary
                )
            case .poll:
                notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.pollHasEnded,
                    emojis: author.emojis.asDictionary
                )
            case .status:
                notificationIndicatorText = createMetaContent(
                    text: .empty,
                    emojis: author.emojis.asDictionary
                )
            case ._other:
                notificationIndicatorText = nil
            }

            var actions = [UIAccessibilityCustomAction]()

            // these notifications can be directly actioned to view the profile
            if type != .follow, type != .followRequest {
                actions.append(
                    UIAccessibilityCustomAction(
                        name: L10n.Common.Controls.Status.showUserProfile,
                        image: nil
                    ) { [weak self] _ in
                        guard let self, let delegate = self.delegate else { return false }
                        delegate.notificationView(self, authorAvatarButtonDidPressed: self.avatarButton)
                        return true
                    }
                )
            }

            if type == .followRequest {
                actions.append(
                    UIAccessibilityCustomAction(
                        name: L10n.Common.Controls.Actions.confirm,
                        image: Asset.Editing.checkmark20.image
                    ) { [weak self] _ in
                        guard let self, let delegate = self.delegate else { return false }
                        delegate.notificationView(self, acceptFollowRequestButtonDidPressed: self.acceptFollowRequestButton)
                        return true
                    }
                )

                actions.append(
                    UIAccessibilityCustomAction(
                        name: L10n.Common.Controls.Actions.delete,
                        image: Asset.Circles.forbidden20.image
                    ) { [weak self] _ in
                        guard let self, let delegate = self.delegate else { return false }
                        delegate.notificationView(self, rejectFollowRequestButtonDidPressed: self.rejectFollowRequestButton)
                        return true
                    }
                )
            }

            notificationActions = actions

        } else {
            notificationIndicatorText = nil
            notificationActions = []
        }

        if let notificationIndicatorText {
            notificationTypeIndicatorLabel.configure(content: notificationIndicatorText)
        } else {
            notificationTypeIndicatorLabel.reset()
        }

        if let me = viewModel.authContext?.mastodonAuthenticationBox.authentication.account() {
            let isMyself = (author == me)
            let isMuting: Bool
            let isBlocking: Bool

            if let relationship = notification.relationship {
                isMuting = relationship.muting
                isBlocking = relationship.blocking || relationship.domainBlocking
            } else {
                isMuting = false
                isBlocking = false
            }

            let menuContext = NotificationView.AuthorMenuContext(name: metaAuthorName.string, isMuting: isMuting, isBlocking: isBlocking, isMyself: isMyself)
            let (menu, actions) = setupAuthorMenu(menuContext: menuContext)
            menuButton.menu = menu
            authorActions = actions
            menuButton.showsMenuAsPrimaryAction = true

            menuButton.isHidden = menuContext.isMyself

        }

        timestampUpdatePublisher
            .prepend(Date())
            .eraseToAnyPublisher()
            .sink { [weak self] now in
                guard let self, let type = MastodonNotificationType(rawValue: notification.entity.type.rawValue) else { return }

                let formattedTimestamp = now.localizedTimeAgo(since: notification.entity.createdAt)
                dateLabel.configure(content: PlaintextMetaContent(string: formattedTimestamp))

                self.accessibilityLabel = [
                    "\(author.displayNameWithFallback) \(type)",
                    author.acct,
                    formattedTimestamp
                ].joined(separator: ", ")
                if self.statusView.isHidden == false {
                    self.accessibilityLabel! += ", " + (self.statusView.accessibilityLabel ?? "")
                }
                if self.quoteStatusViewContainerView.isHidden == false {
                    self.accessibilityLabel! += ", " + (self.quoteStatusView.accessibilityLabel ?? "")
                }

            }
            .store(in: &disposeBag)
    }
}
