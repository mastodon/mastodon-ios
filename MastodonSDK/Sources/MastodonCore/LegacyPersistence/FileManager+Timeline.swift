// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

public extension FileManager {

    // Retrieve
    func cachedHomeTimeline(for userId: UserIdentifier) throws -> [MastodonStatus] {
        try cached(timeline: .homeTimeline(userId)).map(MastodonStatus.fromEntity)
    }

    func cachedNotificationsAll(for userId: UserIdentifier) throws -> [Mastodon.Entity.Notification] {
        try cached(timeline: .notificationsAll(userId))
    }

    func cachedNotificationsMentions(for userId: UserIdentifier) throws -> [Mastodon.Entity.Notification] {
        try cached(timeline: .notificationsMentions(userId))
    }

    // Create
    func cacheHomeTimeline(items: [MastodonStatus], for userIdentifier: UserIdentifier) {
        cache(items.map { $0.entity }, timeline: .homeTimeline(userIdentifier))
    }

    func cacheNotificationsAll(items: [Mastodon.Entity.Notification], for userIdentifier: UserIdentifier) {
        cache(items, timeline: .notificationsAll(userIdentifier))
    }

    func cacheNotificationsMentions(items: [Mastodon.Entity.Notification], for userIdentifier: UserIdentifier) {
        cache(items, timeline: .notificationsMentions(userIdentifier))
    }
}

private extension FileManager {
    static let cacheItemsLimit: Int = 100 // max number of items to cache

    func cached<T: Decodable>(timeline: Persistence) throws -> [T] {
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
    

    func cache<T: Encodable>(_ items: [T], timeline: Persistence) {
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

    func invalidate(timeline: Persistence) {
        guard let cachesDirectory else { return }

        let filePath = timeline.filepath(baseURL: cachesDirectory)

        try? removeItem(at: filePath)
    }
}
