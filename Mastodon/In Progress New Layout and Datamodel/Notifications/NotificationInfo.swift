// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

protocol NotificationInfo {
    var id: String { get }
    var newestNotificationID: String { get }
    var oldestNotificationID: String { get }
    var typeFromServer: Mastodon.Entity.NotificationType { get }
    var isGrouped: Bool { get }
    var notificationsCount: Int { get }
    var authorsCount: Int { get }
    var primaryAuthorAccount: Mastodon.Entity.Account? { get }
    var authorAvatarUrls: [URL] { get }
    func availableRelationshipElement() async -> RelationshipElement?
    func fetchRelationshipElement() async -> RelationshipElement
    var adminReport: Mastodon.Entity.Report? { get }
    var relationshipSeveranceEvent: Mastodon.Entity.RelationshipSeveranceEvent?
    { get }
}

enum GroupedNotificationType {
    // TODO: update to use StatusViewModel rather than Status
    case follow(from: NotificationSourceAccounts)  // Someone followed you
    case followRequest(from: Mastodon.Entity.Account)  // Someone requested to follow you
    case mention(Mastodon.Entity.Status?)  // Someone mentioned you in their status
    case reblog(Mastodon.Entity.Status?)  // Someone boosted one of your statuses
    case quote(Mastodon.Entity.Status?)  // Someone quoted one of your statuses
    case quotedUpdate(Mastodon.Entity.Status?)  // Someone edited a post that you quoted
    case favourite(Mastodon.Entity.Status?)  // Someone favourited one of your statuses
    case poll(Mastodon.Entity.Status?)  // A poll you have voted in or created has ended
    case status(Mastodon.Entity.Status?)  // Someone you enabled notifications for has posted a status
    case update(Mastodon.Entity.Status?)  // A status you interacted with has been edited
    case adminSignUp  // Someone signed up (optionally sent to admins)
    case adminReport(Mastodon.Entity.Report?, URL?)  // A new report has been filed
    case severedRelationships(Mastodon.Entity.RelationshipSeveranceEvent?, URL?)  // Some of your follow relationships have been severed as a result of a moderation or block event
    case moderationWarning(Mastodon.Entity.AccountWarning?, URL?)  //  A moderator has taken action against your account or has sent you a warning

    case _other(String)
}

struct GroupedNotificationInfo: Identifiable {
    func availableRelationshipElement() async -> RelationshipElement? {
        return relationshipElement
    }

    func fetchRelationshipElement() async -> RelationshipElement {
        return relationshipElement
    }

    let id: String
    let timestamp: Date?
    let oldestNotificationID: String
    let newestNotificationID: String

    let groupedNotificationType: GroupedNotificationType

    let sourceAccounts: NotificationSourceAccounts

    var relationshipElement: RelationshipElement {
        switch groupedNotificationType {
        case .follow(let accountsInfo):
            if accountsInfo.primaryAuthorAccount != nil {
                return .unfetched(groupedNotificationType)
            } else {
                return .error(nil)
            }
        case .followRequest:
            if sourceAccounts.totalActorCount == 1 {
                return .unfetched(groupedNotificationType)
            } else {
                return .error(nil)
            }
        default:
            return .noneNeeded
        }
    }

    let post: GenericMastodonPost?

    let primaryNavigation: NotificationRowViewModel.NotificationNavigation?
}

extension Mastodon.Entity.Notification: NotificationInfo {
    var isGrouped: Bool {
        return false
    }

    var oldestNotificationID: String {
        return id
    }
    var newestNotificationID: String {
        return id
    }

    var typeFromServer: Mastodon.Entity.NotificationType {
        return type
    }

    var authorsCount: Int { 1 }
    var notificationsCount: Int { 1 }
    var primaryAuthorAccount: Mastodon.Entity.Account? { account }

    var authorAvatarUrls: [URL] {
        if let domain = account.domain {
            return [account.avatarImageURLWithFallback(domain: domain)]
        } else if let url = account.avatarImageURL() {
            return [url]
        } else {
            return []
        }
    }

    @MainActor
    func availableRelationshipElement() -> RelationshipElement? {
        if let relationship = MastodonFeedItemCacheManager.shared
            .currentRelationship(toAccount: account.id)
        {
            return relationship.relationshipElement
        }
        return nil
    }

    @MainActor
    func fetchRelationshipElement() async -> RelationshipElement {
        do {
            try await fetchRelationship()
            if let available = availableRelationshipElement() {
                return available
            } else {
                return .noneNeeded
            }
        } catch {
            return .error(error)
        }
    }
    private func fetchRelationship() async throws {
        guard
            let authBox = await AuthenticationServiceProvider.shared
                .currentActiveUser.value
        else { return }
        let relationship = try await APIService.shared.relationship(
            forAccounts: [account], authenticationBox: authBox)
        await MastodonFeedItemCacheManager.shared.addToCache(relationship)
    }
}

