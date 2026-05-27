//
//  Persistence.swift
//  Persistence
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

public enum Persistence {
    case searchHistory(UserIdentifier)
    case homeTimeline(UserIdentifier)
    case notificationsMentions(UserIdentifier)
    case notificationsAll(UserIdentifier)
    case groupedNotificationsMentions(UserIdentifier)
    case groupedNotificationsMentionsAccounts(UserIdentifier)
    case groupedNotificationsMentionsPartialAccounts(UserIdentifier)
    case groupedNotificationsMentionsStatuses(UserIdentifier)
    case groupedNotificationsAll(UserIdentifier)
    case groupedNotificationsAllAccounts(UserIdentifier)
    case groupedNotificationsAllPartialAccounts(UserIdentifier)
    case groupedNotificationsAllStatuses(UserIdentifier)
    case lastReadMarkers(UserIdentifier)
    case accounts(UserIdentifier)

    private var filename: String {
        switch self {
        case let .searchHistory(userIdentifier):
            return "search_history_\(userIdentifier.globallyUniqueUserIdentifier))"
        case let .homeTimeline(userIdentifier):
            return "home_timeline_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .notificationsMentions(userIdentifier):
            return "notifications_mentions_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .notificationsAll(userIdentifier):
            return "notifications_all_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsMentions(userIdentifier):
            return "grouped_notifications_mentions_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsMentionsStatuses(userIdentifier):
            return "grouped_notifications_mentions_relevant_statuses_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsMentionsAccounts(userIdentifier):
            return "grouped_notifications_mentions_relevant_accounts_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsMentionsPartialAccounts(userIdentifier):
            return "grouped_notifications_mentions_relevant_partialAccounts_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsAll(userIdentifier):
            return "grouped_notifications_all_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsAllStatuses(userIdentifier):
            return "grouped_notifications_all_relevant_statuses_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsAllAccounts(userIdentifier):
            return "grouped_notifications_all_relevant_accounts_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .groupedNotificationsAllPartialAccounts(userIdentifier):
            return "grouped_notifications_all_relevant_partialAccounts_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .lastReadMarkers(userIdentifier):
            return "last_read_markers_\(userIdentifier.globallyUniqueUserIdentifier)"
        case let .accounts(userIdentifier):
            return "account_\(userIdentifier.globallyUniqueUserIdentifier)"
        }
    }

    public func filepath(baseURL: URL) -> URL {
        baseURL
            .appending(path: filename)
            .appendingPathExtension("json")
    }
}


extension Persistence {
    public enum MastodonUser { }
    public enum Status { }
    public enum SearchHistory { }
    public enum Notification { }
}

extension Persistence {
    public class PersistCache<T> {
        var dictionary: [String : T] = [:]
        
        public init(dictionary: [String : T] = [:]) {
            self.dictionary = dictionary
        }
    }
}

