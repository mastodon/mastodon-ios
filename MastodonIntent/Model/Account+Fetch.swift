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
    static func fetch(in managedObjectContext: NSManagedObjectContext) async throws -> [Account] {
        // get accounts
        let results = AuthenticationServiceProvider.shared.authentications
        var accounts = [Account]()
        for mastodonAuthentication in results {
            guard let user = try? await mastodonAuthentication.me() else {
                continue
            }
            let account = Account(
                identifier: mastodonAuthentication.identifier.uuidString,
                display: user.displayNameWithFallback,
                subtitle: user.acctWithDomain,
                image: user.avatarImageURL().flatMap { INImage(url: $0) }
            )
            account.name = user.displayNameWithFallback
            account.username = user.acctWithDomain
            accounts.append(account)
        }

        return accounts
    }
    
}

extension Array where Element == Account {
    func mastodonAuthentication(in managedObjectContext: NSManagedObjectContext) throws -> [MastodonAuthentication] {
        let identifiers = self
            .compactMap { $0.identifier }
            .compactMap { UUID(uuidString: $0) }
        let results = AuthenticationServiceProvider.shared.authentications.filter({ identifiers.contains($0.identifier) })
        return results
    }
    
}
