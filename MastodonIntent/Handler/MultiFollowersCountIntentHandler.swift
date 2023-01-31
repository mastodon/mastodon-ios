// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Intents
import MastodonCore
import MastodonSDK
import MastodonLocalization

class MultiFollowersCountIntentHandler: INExtension, MultiFollowersCountIntentHandling {
    func provideAccountsOptionsCollection(for intent: MultiFollowersCountIntent, searchTerm: String?) async throws -> INObjectCollection<NSString> {
        guard
            let searchTerm = searchTerm,
            let authenticationBox = WidgetExtension.appContext
                .authenticationService
                .mastodonAuthenticationBoxes
                .first
        else {
            return INObjectCollection(items: [])
        }

        let results = try await WidgetExtension.appContext
            .apiService
            .search(query: .init(q: searchTerm), authenticationBox: authenticationBox)
        
        return INObjectCollection(items: results.value.accounts.map { $0.acctWithDomain(localDomain: authenticationBox.domain) as NSString })
    }
}
