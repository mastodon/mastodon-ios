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
        let accounts: [Account] = try await managedObjectContext.perform {
            let results = try MastodonAuthentication.fetch(in: managedObjectContext)
            let accounts = results.compactMap { mastodonAuthentication -> Account? in
                let user = mastodonAuthentication.user
                let account = Account(
                    identifier: mastodonAuthentication.identifier.uuidString,
                    display: user.displayNameWithFallback,
                    subtitle: user.acctWithDomain,
                    image: user.avatarImageURL().flatMap { INImage(url: $0) }
                )
                account.name = user.displayNameWithFallback
                account.username = user.acctWithDomain
                return account
            }
            return accounts
        }   // end managedObjectContext.perform

        return accounts
    }
    
}

extension Array where Element == Account {
    func mastodonAuthentication(in managedObjectContext: NSManagedObjectContext) throws -> [MastodonAuthentication] {
        let identifiers = self
            .compactMap { $0.identifier }
            .compactMap { UUID(uuidString: $0) }
        let request = MastodonAuthentication.sortedFetchRequest
        request.predicate = MastodonAuthentication.predicate(identifiers: identifiers)
        let results = try managedObjectContext.fetch(request)
        return results
    }
    
}
