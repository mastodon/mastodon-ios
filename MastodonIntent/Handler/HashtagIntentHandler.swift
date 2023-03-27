// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Intents

class HashtagIntentHandler: INExtension, HashtagIntentHandling {
    func provideHashtagOptionsCollection(for intent: HashtagIntent, searchTerm: String?) async throws -> INObjectCollection<NSString> {

        guard let authenticationBox = WidgetExtension.appContext
            .authenticationService
            .mastodonAuthenticationBoxes
            .first
        else {
            return INObjectCollection(items: [])
        }

        var results: [NSString] = []

        if let searchTerm, searchTerm.isEmpty == false {
            let searchResults = try await WidgetExtension.appContext
                .apiService
                .search(query: .init(q: searchTerm, type: .hashtags), authenticationBox: authenticationBox)
                .value
                .hashtags.compactMap { $0.name as NSString }
            results = searchResults

        } else {
            //TODO: Show hashtags I follow
        }

        return INObjectCollection(items: results)

    }
}
