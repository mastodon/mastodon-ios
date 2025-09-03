//
//  GroupedNotificationFeedLoader.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 1/31/25.
//

import Combine
import Foundation
import MastodonCore
import MastodonSDK
import UIKit
import os.log

@MainActor
final class UngroupedNotificationsFeedLoader: MastodonFeedLoader<GroupedNotificationInfo, [Mastodon.Entity.Notification]> {
    private let user: MastodonUserIdentifier
    private let kind: MastodonFeedKind
    
    init(_ kind: MastodonFeedKind, forUser user: MastodonUserIdentifier) {
        self.kind = kind
        self.user = user
        
        switch kind {
        case .home:
            fatalError("nonsensical")
        case .notificationsAll, .notificationsMentionsOnly:
            super.init(UngroupedNotificationCacheManager(feedKind: kind, userIdentifier: user))
        case .notificationsWithAccount:
            super.init(UngroupedNotificationCacheManager(feedKind: kind, userIdentifier: user)) // TODO: make sure this works to keep the records updated but doesn't attempt to save any cache to disk
        }
    }
    
    private func getUngroupedNotifications(
        withScope scope: APIService.MastodonNotificationScope? = nil,
        accountID: String? = nil, olderThan maxID: String? = nil, newerThan minID: String?
    ) async throws -> [Mastodon.Entity.Notification] {
        
        assert(scope != nil || accountID != nil, "need a scope or an accountID")
        
        guard
            let authenticationBox = AuthenticationServiceProvider.shared
                .currentActiveUser.value
        else { throw APIService.APIError.implicit(.authenticationMissing) }
        
        let ungrouped = try await APIService.shared.notifications(
            olderThan: maxID, fromAccount: accountID, scope: scope,
            authenticationBox: authenticationBox
        ).value
        
        if accountID != nil {
            // TODO: Remove this when NotificationRequestsTableViewController no longer needs it.  See IOS-424.
            for item in ungrouped {
                MastodonFeedItemCacheManager.shared.addToCache(item)
            }
        }
        
        return ungrouped
    }
    
    override func fetchResults(for request: MastodonFeedLoaderRequest) async throws -> [Mastodon.Entity.Notification] {
        let olderThan: String?
        let newerThan: String?
        switch request {
        case .newer:
            olderThan = nil
            newerThan = records.allRecords.first?.newestNotificationID
        case .older:
            olderThan = records.allRecords.last?.oldestNotificationID
            newerThan = nil
        case .reload:
            olderThan = nil
            newerThan = nil
        case .newerThan, .olderThan:
            throw MastodonFeedLoaderError.requestNotImplemented
        }
        
        switch kind {
        case .home:
            assertionFailure("NOT IMPLEMENTED")
            return try await getUngroupedNotifications(
                withScope: .everything, olderThan: olderThan, newerThan: newerThan)
        case .notificationsAll:
            return try await getUngroupedNotifications(
                withScope: .everything, olderThan: olderThan, newerThan: newerThan)
        case .notificationsMentionsOnly:
            return try await getUngroupedNotifications(
                withScope: .mentions, olderThan: olderThan, newerThan: newerThan)
        case .notificationsWithAccount(let accountID):
            return try await getUngroupedNotifications(accountID: accountID, olderThan: olderThan, newerThan: newerThan)
        }
    }
    
    override func filteredResults(fromCachedType unfiltered: [Mastodon.Entity.Notification]) -> [GroupedNotificationInfo] {
        return unfiltered
            .filter({ !shouldHide($0.status?.filtered ?? []) })
            .map({ notification in
                let sourceAccounts = NotificationSourceAccounts(myAccountID: user.domain, accounts: [notification.account], totalActorCount: 1)
                let notificationType = GroupedNotificationType(notification, myAccountDomain: user.domain, sourceAccounts: sourceAccounts, adminReportID: nil)
                let navigation = NotificationRowViewModel.defaultNavigation(notificationType, isGrouped: false, primaryAccount: notification.account)
                let post = notification.status == nil ? nil : GenericMastodonPost.fromStatus(notification.status!)
                let info = GroupedNotificationInfo(id: notification.id, timestamp: notification.createdAt, oldestNotificationID: notification.id, newestNotificationID: notification.id, groupedNotificationType: notificationType, sourceAccounts: sourceAccounts, post:  post, primaryNavigation: navigation)
                return info
            })
    }
}

@MainActor
final class GroupedNotificationsFeedLoader: MastodonFeedLoader<GroupedNotificationInfo, Mastodon.Entity.GroupedNotificationsResults> {
    
    private let user: MastodonUserIdentifier
    private let kind: MastodonFeedKind

    init(_ kind: MastodonFeedKind, forUser user: MastodonUserIdentifier) {
        self.user = user
        self.kind = kind
        switch kind {
        case .home, .notificationsWithAccount:
            fatalError("nonsensical")
        case .notificationsAll, .notificationsMentionsOnly:
            super.init(GroupedNotificationCacheManager(feedKind: kind, userIdentifier: user))
        }
    }
    
    override func fetchResults(for request: MastodonFeedLoaderRequest) async throws -> Mastodon.Entity.GroupedNotificationsResults {
        let olderThan: String?
        let newerThan: String?
        switch request {
        case .newer:
            olderThan = nil
            newerThan = records.allRecords.first?.newestNotificationID
        case .older:
            olderThan = records.allRecords.last?.oldestNotificationID
            newerThan = nil
        case .reload:
            olderThan = nil
            newerThan = nil
        case .newerThan, .olderThan:
            throw MastodonFeedLoaderError.requestNotImplemented
        }
        
        switch kind {
        case .home, .notificationsWithAccount:
            assertionFailure("NOT IMPLEMENTED")
            return try await getGroupedNotifications(
                withScope: .everything, olderThan: olderThan, newerThan: newerThan)
        case .notificationsAll:
            return try await getGroupedNotifications(
                withScope: .everything, olderThan: olderThan, newerThan: newerThan)
        case .notificationsMentionsOnly:
            return try await getGroupedNotifications(
                withScope: .mentions, olderThan: olderThan, newerThan: newerThan)
        }
    }
    
    override func filteredResults(fromCachedType results: Mastodon.Entity.GroupedNotificationsResults) -> [GroupedNotificationInfo] {
      
        let fullAccounts = results.accounts.reduce(
            into: [String: Mastodon.Entity.Account]()
        ) { partialResult, account in
            partialResult[account.id] = account
        }
        let partialAccounts = results.partialAccounts?.reduce(
            into: [String: Mastodon.Entity.PartialAccountWithAvatar]()
        ) { partialResult, account in
            partialResult[account.id] = account
        }
        
        let statuses = results.statuses.reduce(
            into: [String: Mastodon.Entity.Status](),
            { partialResult, status in
                partialResult[status.id] = status
            })
        
        return results.notificationGroups.map { group in
            let accounts: [AccountInfo] = group.sampleAccountIDs.compactMap { accountID in
                return fullAccounts[accountID] ?? partialAccounts?[accountID]
            }
            
            let sourceAccounts = NotificationSourceAccounts(
                myAccountID: user.userID, accounts: accounts,
                totalActorCount: group.notificationsCount)
            
            let status = group.statusID == nil ? nil : statuses[group.statusID!]
            
            let type = GroupedNotificationType(
                group, myAccountDomain: user.domain, sourceAccounts: sourceAccounts, status: status, adminReportID: group.adminReport?.id)
            
            let post = status == nil ? nil : GenericMastodonPost.fromStatus(status!)
            
            return GroupedNotificationInfo(
                id: group.id,
                timestamp: group.latestPageNotificationAt,
                oldestNotificationID: group.pageNewestID ?? "",
                newestNotificationID: group.pageOldestID ?? "",
                groupedNotificationType: type,
                sourceAccounts: sourceAccounts,
                post: post,
                primaryNavigation: NotificationRowViewModel.defaultNavigation(
                    type, isGrouped: group.notificationsCount > 1,
                    primaryAccount: sourceAccounts.primaryAuthorAccount)
            )
        }
    }
}

extension GroupedNotificationsFeedLoader {
    private func getGroupedNotifications(
        withScope scope: APIService.MastodonNotificationScope, olderThan maxID: String? = nil, newerThan minID: String?
    ) async throws -> Mastodon.Entity.GroupedNotificationsResults {
        guard
            let authenticationBox = AuthenticationServiceProvider.shared
                .currentActiveUser.value
        else { throw APIService.APIError.implicit(.authenticationMissing) }

        let adminFilterPreferences = await BodegaPersistence.Notifications.currentPreferences(for: authenticationBox)
        let results = try await APIService.shared.groupedNotifications(
            olderThan: maxID, newerThan: minID, fromAccount: nil, scope: scope, excludingAdminTypes: adminFilterPreferences?.excludedNotificationTypes,
            authenticationBox: authenticationBox
        )

        return results
    }
}

func shouldHide(_ filterResults: [Mastodon.Entity.ServerFilterResult]) -> Bool {
    for result in filterResults {
        guard let keywordMatches = result.keywordMatches, let statusMatches = result.statusMatches else { return false }
        if result.filter.filterAction == .hide && (!keywordMatches.isEmpty || !statusMatches.isEmpty) {
            return true
        }
    }
    return false
}

extension Array<Mastodon.Entity.Notification>: CacheableFeed {
    public var hasResults: Bool {
        return !isEmpty
    }
}

extension Mastodon.Entity.GroupedNotificationsResults: CacheableFeed {
    public var hasResults: Bool {
        hasContents
    }
}
