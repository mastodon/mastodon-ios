//
//  Account.swift
//  MastodonIntent
//
//  Created by MainasuK on 2022-6-9.
//

import Foundation
import Intents
import MastodonCore

extension Account {

    @MainActor
    static func loadFromCache() -> [Account] {
        let accounts = AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.compactMap { authBox -> Account? in
            guard let authenticatedAccount = authBox.cachedAccount else {
                return nil
            }
            let account = Account(
                identifier: authBox.authentication.identifier.uuidString,
                display: authenticatedAccount.displayNameWithFallback,
                subtitle: authenticatedAccount.acctWithDomain,
                image: authenticatedAccount.avatarImageURL().flatMap { INImage(url: $0) }
            )
            account.name = authenticatedAccount.displayNameWithFallback
            account.username = authenticatedAccount.acctWithDomain
            return account
        }

        return accounts
    }

}
