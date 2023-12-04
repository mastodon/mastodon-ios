// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

extension FileManager {
    private static let cacheItemsLimit: Int = 100 // max number of items to cache
    
    // Retrieve
    func cachedHomeTimeline(for userId: String) throws -> [MastodonStatus] {
        try cached(timeline: .homeTimeline(userId)).map(MastodonStatus.fromEntity)
    }
    
    func cachedNotificationsAll(for userId: String) throws -> [Mastodon.Entity.Notification] {
        try cached(timeline: .notificationsAll(userId))
    }
    
    func cachedNotificationsMentions(for userId: String) throws -> [Mastodon.Entity.Notification] {
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
    func cacheHomeTimeline(items: [MastodonStatus], for userId: String) {
        cache(items.map { $0.entity }, timeline: .homeTimeline(userId))
    }
    
    func cacheNotificationsAll(items: [Mastodon.Entity.Notification], for userId: String) {
        cache(items, timeline: .notificationsAll(userId))
    }
    
    func cacheNotificationsMentions(items: [Mastodon.Entity.Notification], for userId: String) {
        cache(items, timeline: .notificationsMentions(userId))
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
    func invalidateHomeTimelineCache(for userId: String) {
        invalidate(timeline: .homeTimeline(userId))
    }
    
    func invalidateNotificationsAll(for userId: String) {
        invalidate(timeline: .notificationsAll(userId))
    }
    
    func invalidateNotificationsMentions(for userId: String) {
        invalidate(timeline: .notificationsMentions(userId))
    }
    
    private func invalidate(timeline: Persistence) {
        guard let cachesDirectory else { return }

        let filePath = timeline.filepath(baseURL: cachesDirectory)

        try? removeItem(at: filePath)
    }
}
