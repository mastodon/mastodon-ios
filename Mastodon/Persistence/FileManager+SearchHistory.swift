// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore

extension FileManager {
    func searchItems(forUser userID: String) throws -> [Persistence.SearchHistory.Item] {
        guard let path = documentsDirectory()?.appending(path: Persistence.searchHistory.filename).appendingPathExtension("json"),
              let data = try? Data(contentsOf: path)
        else { return [] }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        do {
            let searchItems = try jsonDecoder.decode([Persistence.SearchHistory.Item].self, from: data)
                .filter { $0.userID == userID }
                .sorted { $0.updatedAt < $1.updatedAt }

            return searchItems
        } catch {
            return []
        }
    }

    func addSearchItem(_ newSearchItem: Persistence.SearchHistory.Item) throws {
        guard let path = documentsDirectory()?.appending(path: Persistence.searchHistory.filename).appendingPathExtension("json") else { return }

        var searchItems = (try? searchItems(forUser: newSearchItem.userID)) ?? []

        searchItems.append(newSearchItem)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        do {
            let data = try jsonEncoder.encode(searchItems)
            try data.write(to: path)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func removeSearchHistory() {
        guard let path = documentsDirectory()?.appending(path: Persistence.searchHistory.filename).appendingPathExtension("json") else { return }

        try? removeItem(at: path)
    }
}

extension FileManager {
    func documentsDirectory() -> URL? {
        return self.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
