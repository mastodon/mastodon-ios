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
        configureAuthor(notification: notification)
        
        guard let type = MastodonNotificationType(rawValue: notification.typeRaw) else {
            assertionFailure()
            return
        }
        
        if let status = notification.status {
            switch type {
            case .follow, .followRequest:
                setAuthorContainerBottomPaddingViewDisplay()
            case .mention, .status:
                statusView.configure(status: status)
                setStatusViewDisplay()
            case .reblog, .favourite, .poll:
                quoteStatusView.configure(status: status)
                setQuoteStatusViewDisplay()
            case ._other:
                setAuthorContainerBottomPaddingViewDisplay()
                assertionFailure()
            }
        } else {
            setAuthorContainerBottomPaddingViewDisplay()
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
        viewModel.timestampFormatter = { (date: Date) in
            date.localizedSlowedTimeAgoSinceNow
        }
        notification.publisher(for: \.createAt)
            .map { $0 as Date? }
            .assign(to: \.timestamp, on: viewModel)
            .store(in: &disposeBag)
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
                    text: L10n.Scene.Notification.userFollowedYou(""),
                    emojis: emojis.asDictionary
                )
            case .followRequest:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.userRequestedToFollowYou(author.displayNameWithFallback),
                    emojis: emojis.asDictionary
                )
            case .mention:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.userMentionedYou(""),
                    emojis: emojis.asDictionary
                )
            case .reblog:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.userRebloggedYourPost(""),
                    emojis: emojis.asDictionary
                )
            case .favourite:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.userFavoritedYourPost(""),
                    emojis: emojis.asDictionary
                )
            case .poll:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.userYourPollHasEnded(""),
                    emojis: emojis.asDictionary
                )
            case .status:
                self.viewModel.notificationIndicatorText = createMetaContent(
                    text: L10n.Scene.Notification.userMentionedYou(""),
                    emojis: emojis.asDictionary
                )
            case ._other:
                self.viewModel.notificationIndicatorText = nil
            }
        }
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
}
