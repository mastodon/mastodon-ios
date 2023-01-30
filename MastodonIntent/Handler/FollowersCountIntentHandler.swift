// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Intents
import MastodonCore
import MastodonSDK
import MastodonLocalization

class FollowersCountIntentHandler: INExtension, FollowersCountIntentHandling {
    func resolveShowChart(for intent: FollowersCountIntent) async -> INBooleanResolutionResult {
        return .success(with: intent.showChart?.boolValue ?? false)
    }
    
    func resolveAccount(for intent: FollowersCountIntent) async -> INStringResolutionResult {
        .confirmationRequired(with: intent.account)
    }

    func provideAccountOptionsCollection(for intent: FollowersCountIntent, searchTerm: String?) async throws -> INObjectCollection<NSString> {
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
        
        debugPrint(results.value.statuses)

        return INObjectCollection(items: results.value.accounts.map { $0.acctWithDomain(localDomain: authenticationBox.domain) as NSString })
    }
}

private extension Mastodon.Entity.Account {
    func acctWithDomain(localDomain: String) -> String {
        guard acct.contains("@") else {
            return "\(acct)@\(localDomain)"
        }
        return acct
    }
}
