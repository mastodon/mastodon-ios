//
//  APIService+Notification.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import OSLog
import class CoreDataStack.Notification

extension APIService {
    
    public enum MastodonNotificationScope: Hashable, CaseIterable {
        case everything
        case mentions
        
        public var includeTypes: [MastodonNotificationType]? {
            switch self {
            case .everything:       return nil
            case .mentions:         return [.mention, .status]
            }
        }
        
        public var excludeTypes: [MastodonNotificationType]? {
            switch self {
            case .everything:       return nil
            case .mentions:         return [.follow, .followRequest, .reblog, .favourite, .poll]
            }
        }
        
        public var _excludeTypes: [Mastodon.Entity.Notification.NotificationType]? {
            switch self {
            case .everything:       return nil
            case .mentions:         return [.follow, .followRequest, .reblog, .favourite, .poll]
            }
        }
    }
    
    public func notifications(
        maxID: Mastodon.Entity.Status.ID?,
        scope: MastodonNotificationScope,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Notification]> {
        let authorization = authenticationBox.userAuthorization
        
        let query = Mastodon.API.Notifications.Query(
            maxID: maxID,
            types: {
                switch scope {
                case .everything:
                    return [
                        .follow,
                        .followRequest,
                        .mention,
                        .reblog,
                        .favourite,
                        .poll,
                        .status,
                    ]
                case .mentions:
                    return [
                        .mention,
                        .status,
                    ]
                }
            }(),
            excludeTypes: {
                switch scope {
                case .everything:
                    return nil
                case .mentions:
                    return [.follow, .followRequest, .reblog, .favourite, .poll]
                }
            }()
        )
        
        let response = try await Mastodon.API.Notifications.getNotifications(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else {
                assertionFailure()
                return
            }
            
            var notifications: [Notification] = []
            for entity in response.value {
                let result = Persistence.Notification.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Notification.PersistContext(
                        domain: authenticationBox.domain,
                        entity: entity,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
                notifications.append(result.notification)
            }
            
            // locate anchor notification
            let anchorNotification: Notification? = {
                guard let maxID = query.maxID else { return nil }
                let request = Notification.sortedFetchRequest
                request.predicate = Notification.predicate(
                    domain: authenticationBox.domain,
                    userID: authenticationBox.userID,
                    id: maxID
                )
                request.fetchLimit = 1
                return try? managedObjectContext.fetch(request).first
            }()
            
            // update hasMore flag for anchor status
            let acct = Feed.Acct.mastodon(domain: authenticationBox.domain, userID: authenticationBox.userID)
            let kind: Feed.Kind = scope == .everything ? .notificationAll : .notificationMentions
            if let anchorNotification = anchorNotification,
               let feed = anchorNotification.feed(kind: kind, acct: acct) {
                feed.update(hasMore: false)
            }
            
            // persist Feed relationship
            let sortedNotifications = notifications.sorted(by: { $0.createAt < $1.createAt })
            let oldestNotification = sortedNotifications.first
            for notification in notifications {
                let _feed = notification.feed(kind: kind, acct: acct)
                if let feed = _feed {
                    feed.update(updatedAt: response.networkDate)
                } else {
                    let feedProperty = Feed.Property(
                        acct: acct,
                        kind: kind,
                        hasMore: false,
                        createdAt: notification.createAt,
                        updatedAt: response.networkDate
                    )
                    let feed = Feed.insert(into: managedObjectContext, property: feedProperty)
                    notification.attach(feed: feed)
                    
                    // set hasMore on oldest notification if is new feed
                    if notification === oldestNotification {
                        feed.update(hasMore: true)
                    }
                }
            }
        }
        
        return response
    }
}

extension APIService {
    
    public func notification(
        notificationID: Mastodon.Entity.Notification.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Notification> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Notifications.getNotification(
            session: session,
            domain: domain,
            notificationID: notificationID,
            authorization: authorization
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else { return }
            _ = Persistence.Notification.createOrMerge(
                in: managedObjectContext,
                context: Persistence.Notification.PersistContext(
                    domain: domain,
                    entity: response.value,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }

}
