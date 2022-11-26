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
import class CoreDataStack.Notification

extension NotificationView {
    public func configure(feed: Feed) {
        guard let notification = feed.notification else {
            assertionFailure()
            return
        }
        
        configure(notification: notification)
    }
}

extension NotificationView {
    public func configure(notification: Notification) {
        viewModel.objects.insert(notification)

        configureAuthor(notification: notification)
        
        guard let type = MastodonNotificationType(rawValue: notification.typeRaw) else {
            assertionFailure()
            return
        }
        
        switch type {
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
    private func configureAuthor(notification: Notification) {
        let author = notification.account
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
        // timestamp
        viewModel.timestamp = notification.createAt
        // notification type indicator
        Publishers.CombineLatest3(
            notification.publisher(for: \.typeRaw),
            author.publisher(for: \.displayName),
            author.publisher(for: \.emojis)
        )
        .sink { [weak self] typeRaw, _, emojis in
            guard let self = self else { return }
            guard let type = MastodonNotificationType(rawValue: typeRaw) else {
                self.viewModel.notificationIndicatorText = nil
                return
            }
            self.viewModel.type = type

            func createMetaContent(text: String, emojis: MastodonContent.Emojis) -> MetaContent {
                let content = MastodonContent(content: text, emojis: emojis)
                guard let metaContent = try? MastodonMetaContent.convert(document: content) else {
                    return PlaintextMetaContent(string: text)
                }
                return metaContent
            }

            // TODO: fix the i18n. The subject should assert place at the string beginning
            switch type {
            case .follow:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.followedYou,
                    emojis: emojis.asDictionary
                )
            case .followRequest:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.requestToFollowYou,
                    emojis: emojis.asDictionary
                )
            case .mention:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.mentionedYou,
                    emojis: emojis.asDictionary
                )
            case .reblog:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.rebloggedYourPost,
                    emojis: emojis.asDictionary
                )
            case .favourite:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.favoritedYourPost,
                    emojis: emojis.asDictionary
                )
            case .poll:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.NotificationDescription.pollHasEnded,
                    emojis: emojis.asDictionary
                )
            case .status:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: .empty,
                    emojis: emojis.asDictionary
                )
            case ._other:
                self.viewModel.notificationIndicatorText = nil
            }
        }
        .store(in: &disposeBag)
        
        let authContext = viewModel.authContext
        // isMuting
        author.publisher(for: \.mutingBy)
            .map { mutingBy in
                guard let authContext = authContext else { return false }
                return mutingBy.contains(where: {
                    $0.id == authContext.mastodonAuthenticationBox.userID
                    && $0.domain == authContext.mastodonAuthenticationBox.domain
                })
            }
            .assign(to: \.isMuting, on: viewModel)
            .store(in: &disposeBag)
        // isBlocking
        author.publisher(for: \.blockingBy)
            .map { blockingBy in
                guard let authContext = authContext else { return false }
                return blockingBy.contains(where: {
                    $0.id == authContext.mastodonAuthenticationBox.userID
                    && $0.domain == authContext.mastodonAuthenticationBox.domain
                })
            }
            .assign(to: \.isBlocking, on: viewModel)
            .store(in: &disposeBag)
        // isMyself
        Publishers.CombineLatest(
            author.publisher(for: \.domain),
            author.publisher(for: \.id)
        )
        .map { domain, id in
            guard let authContext = authContext else { return false }
            return authContext.mastodonAuthenticationBox.domain == domain
                && authContext.mastodonAuthenticationBox.userID == id
        }
        .assign(to: \.isMyself, on: viewModel)
        .store(in: &disposeBag)
        // follow request state
        notification.publisher(for: \.followRequestState)
            .assign(to: \.followRequestState, on: viewModel)
            .store(in: &disposeBag)
        notification.publisher(for: \.transientFollowRequestState)
            .assign(to: \.transientFollowRequestState, on: viewModel)
            .store(in: &disposeBag)
    }
}
