// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public extension FileManager {
    func searchItems(for userId: UserIdentifier) throws -> [Persistence.SearchHistory.Item] {
        guard let documentsDirectory else { return [] }

        let searchHistoryPath = Persistence.searchHistory(userId).filepath(baseURL: documentsDirectory)

        guard let data = try? Data(contentsOf: searchHistoryPath) else { return [] }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        do {
            let searchItems = try jsonDecoder.decode([Persistence.SearchHistory.Item].self, from: data)
                .sorted { $0.updatedAt > $1.updatedAt }

            return searchItems
        } catch {
            return []
        }
    }

    func addSearchItem(_ newSearchItem: Persistence.SearchHistory.Item, for userId: UserIdentifier) throws {
        var searchItems = (try? searchItems(for: userId)) ?? []

        if let index = searchItems.firstIndex(of: newSearchItem) {
            searchItems.remove(at: index)
        }

        searchItems.append(newSearchItem)

        storeJSON(searchItems, .searchHistory(userId))
    }

    func removeSearchHistory(for userId: UserIdentifier) {
        let searchItems = (try? searchItems(for: userId)) ?? []
        let newSearchItems = searchItems.filter { $0.userID != userId.userID }

        storeJSON(newSearchItems, .searchHistory(userId))
    }

    private func storeJSON(_ encodable: Encodable, _ persistence: Persistence) {
        guard let documentsDirectory else { return }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        do {
            let data = try jsonEncoder.encode(encodable)

            let searchHistoryPath = persistence.filepath(baseURL: documentsDirectory)
            try data.write(to: searchHistoryPath)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}
