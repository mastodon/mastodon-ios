// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack // Needed for MastodonFollowRequestState

//@available(*, deprecated, message: "migrate to MastodonFeedLoader and MastodonFeedItemIdentifier")
public final class MastodonFeed {
    
    public enum Kind {

        case home(timeline: TimelineContext)
        case notificationAll
        case notificationMentions
        case notificationAccount(String)

        public enum TimelineContext: Equatable {
            case home
            case `public`
            case list(String)
            case hashtag(String)
        }
    }
    
    public let id: String
    
    @Published
    public var hasMore: Bool = false
    
    @Published
    public var isLoadingMore: Bool = false
    
    public let status: MastodonStatus?
    public let relationship: Mastodon.Entity.Relationship?
    public let notification: Mastodon.Entity.Notification?
    
    public let kind: Kind

    init(hasMore: Bool, isLoadingMore: Bool, status: MastodonStatus?, notification: Mastodon.Entity.Notification?, relationship: Mastodon.Entity.Relationship?, kind: Kind) {
        self.id = notification?.id ?? status?.id ?? UUID().uuidString
        self.hasMore = hasMore
        self.isLoadingMore = isLoadingMore
        self.status = status
        self.notification = notification
        self.relationship = relationship
        self.kind = kind
    }
}

public extension MastodonFeed {
    static func fromStatus(_ status: MastodonStatus, kind: Kind, hasMore: Bool? = nil) -> MastodonFeed {
        MastodonFeed(
            hasMore: hasMore ?? false,
            isLoadingMore: false,
            status: status,
            notification: nil,
            relationship: nil,
            kind: kind
        )
    }
    
    static func fromNotification(_ notification: Mastodon.Entity.Notification, relationship: Mastodon.Entity.Relationship?, kind: Kind) -> MastodonFeed {
        MastodonFeed(
            hasMore: false,
            isLoadingMore: false,
            status: {
                guard let status = notification.status else {
                    return nil
                }
                return .fromEntity(status)
            }(),
            notification: notification,
            relationship: relationship,
            kind: kind
        )
    }
}

extension MastodonFeed: Hashable {
    public static func == (lhs: MastodonFeed, rhs: MastodonFeed) -> Bool {
        lhs.id == rhs.id && 
        lhs.status?.entity == rhs.status?.entity &&
        lhs.status?.poll == rhs.status?.poll &&
        lhs.status?.reblog?.entity == rhs.status?.reblog?.entity &&
        lhs.status?.reblog?.poll == rhs.status?.reblog?.poll &&
        lhs.status?.showDespiteContentWarning == rhs.status?.showDespiteContentWarning &&
        lhs.status?.reblog?.showDespiteContentWarning == rhs.status?.reblog?.showDespiteContentWarning &&
        lhs.status?.showDespiteFilter == rhs.status?.showDespiteFilter &&
        lhs.status?.reblog?.showDespiteFilter == rhs.status?.reblog?.showDespiteFilter &&
        lhs.status?.poll == rhs.status?.poll &&
        lhs.status?.reblog?.poll == rhs.status?.reblog?.poll &&
        lhs.status?.poll?.entity == rhs.status?.poll?.entity &&
        lhs.status?.reblog?.poll?.entity == rhs.status?.reblog?.poll?.entity &&
        lhs.isLoadingMore == rhs.isLoadingMore
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(status?.entity)
        hasher.combine(status?.poll)
        hasher.combine(status?.reblog?.entity)
        hasher.combine(status?.reblog?.poll)
        hasher.combine(status?.showDespiteContentWarning)
        hasher.combine(status?.reblog?.showDespiteContentWarning)
        hasher.combine(status?.showDespiteFilter)
        hasher.combine(status?.reblog?.showDespiteFilter)
        hasher.combine(status?.poll)
        hasher.combine(status?.reblog?.poll)
        hasher.combine(status?.poll?.entity)
        hasher.combine(status?.reblog?.poll?.entity)
        hasher.combine(isLoadingMore)
    }
    
}


public enum MastodonFeedItemIdentifier: Hashable, Identifiable, Equatable {
    case status(id: String)
    case notification(id: String)
    case notificationGroup(id: String)
    
    public var id: String {
        switch self {
        case .status(let id):
            return id
        case .notification(let id):
            return id
        case .notificationGroup(let id):
            return id
        }
    }
}

public enum MastodonFeedKind {
    case home
    case notificationsAll
    case notificationsMentionsOnly
    case notificationsWithAccount(String)
}

@MainActor
public class MastodonFeedItemCacheManager {
    private var statusCache = [ String : Mastodon.Entity.Status ]()
    private var notificationsCache = [ String : Mastodon.Entity.Notification ]()
    private var groupedNotificationsCache = [ String : Mastodon.Entity.NotificationGroup ]()
    private var relationshipsCache = [ String : Mastodon.Entity.Relationship ]() // key is id of the not-me account
    private var fullAccountsCache = [ String : Mastodon.Entity.Account ]()
    private var partialAccountsCache = [ String : Mastodon.Entity.PartialAccountWithAvatar ]()
    private var filterOverrides = Set<String>()
    private var contentWarningOverrides = Set<String>()
    private var followRequestStates = [ String : MastodonFollowRequestState ]()
    
    private init(){}
    public static let shared = MastodonFeedItemCacheManager()

    public func clear() { // TODO: call this when switching accounts
        statusCache.removeAll()
        notificationsCache.removeAll()
        groupedNotificationsCache.removeAll()
        relationshipsCache.removeAll()
    }
    
    public func addToCache(_ item: Any) {
        if let status = item as? Mastodon.Entity.Status {
            statusCache[status.id] = status
            let displayableStatus = status.reblog ?? status
        } else if let notification = item as? Mastodon.Entity.Notification {
            notificationsCache[notification.id] = notification
        } else if let notificationGroup = item as? Mastodon.Entity.NotificationGroup {
            groupedNotificationsCache[notificationGroup.id] = notificationGroup
        } else if let relationship = item as? Mastodon.Entity.Relationship {
            relationshipsCache[relationship.id] = relationship
        } else if let fullAccount = item as? Mastodon.Entity.Account {
            partialAccountsCache.removeValue(forKey: fullAccount.id)
            fullAccountsCache[fullAccount.id] = fullAccount
        } else if let partialAccount = item as? Mastodon.Entity.PartialAccountWithAvatar {
            partialAccountsCache[partialAccount.id] = partialAccount
        } else {
            assertionFailure("cannot cache \(item)")
        }
    }
    
    public func cachedItem(_ identifier: MastodonFeedItemIdentifier) -> Any? {
        switch identifier {
        case .status(let id):
            return statusCache[id]
        case .notification(let id):
            return notificationsCache[id]
        case .notificationGroup(let id):
            return groupedNotificationsCache[id]
        }
    }
    
    public func filterableStatus(associatedWith identifier: MastodonFeedItemIdentifier) -> Mastodon.Entity.Status? {
        guard let cachedItem = cachedItem(identifier) else { return nil }
        if let status = cachedItem as? Mastodon.Entity.Status {
            return status.reblog ?? status
        } else if let notification = cachedItem as? Mastodon.Entity.Notification {
            return notification.status?.reblog ?? notification.status
        } else if let notificationGroup = cachedItem as? Mastodon.Entity.NotificationGroup {
            guard let statusID = notificationGroup.statusID else { return nil }
            let status = statusCache[statusID]
            return status?.reblog ?? status
//        } else if let relationship = cachedItem as? Mastodon.Entity.Relationship {
//            return nil
        } else {
            return nil
        }
    }
    
    public func currentRelationship(toAccount accountID: String) -> Mastodon.Entity.Relationship? {
        return relationshipsCache[accountID]
    }
    
    public func partialAccount(_ id: String) -> Mastodon.Entity.PartialAccountWithAvatar? {
        return partialAccountsCache[id]
    }
    
    public func fullAccount(_ id: String) -> Mastodon.Entity.Account? {
        return fullAccountsCache[id]
    }
    
    private func contentStatusID(forStatus statusID: String) -> String {
        guard let status = statusCache[statusID] else { return statusID }
        return status.reblog?.id ?? statusID
    }
    
    public func shouldShowDespiteContentWarning(statusID: String) -> Bool {
        return contentWarningOverrides.contains(contentStatusID(forStatus: statusID))
    }
    
    public func shouldShowDespiteFilter(statusID: String) -> Bool {
        return filterOverrides.contains(contentStatusID(forStatus: statusID))
    }
    
    public func toggleFilteredVisibility(ofStatus statusID: String) {
        let contentStatusID = contentStatusID(forStatus: statusID)
        if filterOverrides.contains(contentStatusID) {
            filterOverrides.remove(contentStatusID)
        } else {
            filterOverrides.insert(contentStatusID)
        }
    }
    
    public func toggleContentWarnedVisibility(ofStatus statusID: String) {
        let contentStatusID = contentStatusID(forStatus: statusID)
        if contentWarningOverrides.contains(contentStatusID) {
            contentWarningOverrides.remove(contentStatusID)
        } else {
            contentWarningOverrides.insert(contentStatusID)
        }
    }
    
    public func followRequestState(forFollowRequestNotification notificationID: String) -> MastodonFollowRequestState {
        if let requestState = followRequestStates[notificationID] {
            return requestState
        } else {
            return .init(state: .none)
        }
    }
    
    public func setFollowRequestState(_ requestState: MastodonFollowRequestState, for followRequestID: String) {
        switch requestState.state {
        case .none:
            followRequestStates.removeValue(forKey: followRequestID)
        default:
            followRequestStates[followRequestID] = requestState
        }
    }
}

extension Mastodon.Entity.Notification {
    
    @MainActor
    public var latestStatus: Mastodon.Entity.Status? {
        var freshStatus: Mastodon.Entity.Status? = nil
        if let statusID = status?.id {
            freshStatus = MastodonFeedItemCacheManager.shared.cachedItem(.status(id: statusID)) as? Mastodon.Entity.Status
        }
        return freshStatus ?? status
    }
}
