// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

extension FileManager {
    private static let cacheHomeItemsLimit: Int = 100 // max number of items to cache
    
    func cachedHomeTimeline(for userId: String) throws -> [MastodonStatus] {
        guard let cachesDirectory else { return [] }

        let filePath = Persistence.homeTimeline(userId).filepath(baseURL: cachesDirectory)

        guard let data = try? Data(contentsOf: filePath) else { return [] }

        do {
            let items = try JSONDecoder().decode([Mastodon.Entity.Status].self, from: data)

            return items.map(MastodonStatus.fromEntity)
        } catch {
            return []
        }
    }
    
    func cacheHomeTimeline(items: [MastodonStatus], for userId: String) {
        guard let cachesDirectory else { return }
        
        let processableItems: [MastodonStatus]
        if items.count > Self.cacheHomeItemsLimit {
            processableItems = items.dropLast(items.count - Self.cacheHomeItemsLimit)
        } else {
            processableItems = items
        }

        do {
            let data = try JSONEncoder().encode(processableItems.map { $0.entity })

            let filePath = Persistence.homeTimeline(userId).filepath(baseURL: cachesDirectory)
            try data.write(to: filePath)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func invalidateHomeTimelineCache(for userId: String) {
        guard let cachesDirectory else { return }

        let filePath = Persistence.homeTimeline(userId).filepath(baseURL: cachesDirectory)

        try? removeItem(at: filePath)
    }
}
