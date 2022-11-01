//
//  APIService+Recommend.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation
import MastodonSDK
import CoreData
import CoreDataStack
import OSLog

extension APIService {
    
    public func suggestionAccount(
        query: Mastodon.API.Suggestions.Query?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
    
        let response = try await Mastodon.API.Suggestions.accounts(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            for entity in response.value {
                _ = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: authenticationBox.domain,
                        entity: entity,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in
        }
        
        return response
    }

    public func suggestionAccountV2(
        query: Mastodon.API.Suggestions.Query?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.V2.SuggestionAccount]> {
        let response = try await Mastodon.API.V2.Suggestions.accounts(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            for entity in response.value {
                _ = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: authenticationBox.domain,
                        entity: entity.account,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in
        }

        return response
    }

}

extension APIService {
    
    public func familiarFollowers(
        query: Mastodon.API.Account.FamiliarFollowersQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.FamiliarFollowers]> {
        let response = try await Mastodon.API.Account.familiarFollowers(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            for entity in response.value {
                for account in entity.accounts {
                    _ = Persistence.MastodonUser.createOrMerge(
                        in: managedObjectContext,
                        context: Persistence.MastodonUser.PersistContext(
                            domain: authenticationBox.domain,
                            entity: account,
                            cache: nil,
                            networkDate: response.networkDate
                        )
                    )
                    
                }   // end for account in
            }   // end for entity in
        }

        return response
    }
    
}
