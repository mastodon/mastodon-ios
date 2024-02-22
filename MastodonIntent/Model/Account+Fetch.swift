//
//  Account.swift
//  MastodonIntent
//
//  Created by MainasuK on 2022-6-9.
//

import Foundation
import CoreData
import CoreDataStack
import Intents
import MastodonCore

extension Account {

    @MainActor
    static func fetch() async throws -> [Account] {
        let accounts = AuthenticationServiceProvider.shared.authentications.compactMap { mastodonAuthentication -> Account? in
            guard let authenticatedAccount = mastodonAuthentication.account() else {
                return nil
            }
            let account = Account(
                identifier: mastodonAuthentication.identifier.uuidString,
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

extension Array where Element == Account {
    func mastodonAuthentication() throws -> [MastodonAuthentication] {
        let identifiers = self
            .compactMap { $0.identifier }
            .compactMap { UUID(uuidString: $0) }
        let results = AuthenticationServiceProvider.shared.authentications.filter({ identifiers.contains($0.identifier) })
        return results
    }
    
}
