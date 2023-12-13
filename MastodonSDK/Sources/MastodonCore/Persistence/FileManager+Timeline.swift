// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

extension FileManager {
    private static let cacheItemsLimit: Int = 100 // max number of items to cache
    
    // Retrieve
    public func cachedHomeTimeline(for userId: UserIdentifier) throws -> [MastodonStatus] {
        try cached(timeline: .homeTimeline(userId)).map(MastodonStatus.fromEntity)
    }
    
    public func cachedNotificationsAll(for userId: UserIdentifier) throws -> [Mastodon.Entity.Notification] {
        try cached(timeline: .notificationsAll(userId))
    }
    
    public func cachedNotificationsMentions(for userId: UserIdentifier) throws -> [Mastodon.Entity.Notification] {
        try cached(timeline: .notificationsMentions(userId))
    }
    

    private func cached<T: Decodable>(timeline: Persistence) throws -> [T] {
        guard let cachesDirectory else { return [] }

        let filePath = timeline.filepath(baseURL: cachesDirectory)

        guard let data = try? Data(contentsOf: filePath) else { return [] }

        do {
            let items = try JSONDecoder().decode([T].self, from: data)

            return items
        } catch {
            return []
        }
    }
    
    // Create
    public func cacheHomeTimeline(items: [MastodonStatus], for userIdentifier: UserIdentifier) {
        cache(items.map { $0.entity }, timeline: .homeTimeline(userIdentifier))
    }
    
    public func cacheNotificationsAll(items: [Mastodon.Entity.Notification], for userIdentifier: UserIdentifier) {
        cache(items, timeline: .notificationsAll(userIdentifier))
    }
    
    public func cacheNotificationsMentions(items: [Mastodon.Entity.Notification], for userIdentifier: UserIdentifier) {
        cache(items, timeline: .notificationsMentions(userIdentifier))
    }
    
    private func cache<T: Encodable>(_ items: [T], timeline: Persistence) {
        guard let cachesDirectory else { return }
        
        let processableItems: [T]
        if items.count > Self.cacheItemsLimit {
            processableItems = items.dropLast(items.count - Self.cacheItemsLimit)
        } else {
            processableItems = items
        }

        do {
            let data = try JSONEncoder().encode(processableItems)

            let filePath = timeline.filepath(baseURL: cachesDirectory)
            try data.write(to: filePath)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    // Delete
    public func invalidateHomeTimelineCache(for userId: UserIdentifier) {
        invalidate(timeline: .homeTimeline(userId))
    }
    
    public func invalidateNotificationsAll(for userId: UserIdentifier) {
        invalidate(timeline: .notificationsAll(userId))
    }
    
    public func invalidateNotificationsMentions(for userId: UserIdentifier) {
        invalidate(timeline: .notificationsMentions(userId))
    }
    
    private func invalidate(timeline: Persistence) {
        guard let cachesDirectory else { return }

        let filePath = timeline.filepath(baseURL: cachesDirectory)

        try? removeItem(at: filePath)
    }
}
