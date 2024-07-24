// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Intents
import MastodonSDK

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
                .hashtags
                .compactMap { "#\($0.name)" as NSString }

            results = searchResults

        } else {
            let followedTags = try await WidgetExtension.appContext.apiService.getFollowedTags(
                domain: authenticationBox.domain,
                query: Mastodon.API.Account.FollowedTagsQuery(limit: nil),
                authenticationBox: authenticationBox)
                .value
                .compactMap { "#\($0.name)" as NSString }

            results = followedTags

        }

        return INObjectCollection(items: results)

    }
}
