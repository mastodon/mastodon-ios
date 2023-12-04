//
//  APIService+Favorite.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/8.
//

import Foundation
import Combine
import MastodonSDK
import CoreData
import CoreDataStack

extension APIService {
    
    private struct MastodonFavoriteContext {
        let statusID: MastodonStatus.ID
        let isFavorited: Bool
        let favoritedCount: Int64
    }
    
    public func favorite(
        status: MastodonStatus,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        
        // update like state and retrieve like context
        let _status = status.reblog ?? status
        let isFavorited = _status.entity.favourited == true
        let favoritedCount = Int64(_status.entity.favouritesCount)

        let favoriteContext = MastodonFavoriteContext(
            statusID: _status.id,
            isFavorited: isFavorited,
            favoritedCount: favoritedCount
        )

        // request like or undo like
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>
        do {
            let response = try await Mastodon.API.Favorites.favorites(
                domain: authenticationBox.domain,
                statusID: favoriteContext.statusID,
                session: session,
                authorization: authenticationBox.userAuthorization,
                favoriteKind: favoriteContext.isFavorited ? .destroy : .create
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
        
        let response = try result.get()
        return response
    }
    
}

extension APIService {
    public func favoritedStatuses(
        limit: Int = onceRequestStatusMaxCount,
        maxID: String? = nil,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let query = Mastodon.API.Favorites.FavoriteStatusesQuery(limit: limit, minID: nil, maxID: maxID)
        
        let response = try await Mastodon.API.Favorites.favoritedStatus(
            domain: authenticationBox.domain,
            session: session,
            authorization: authenticationBox.userAuthorization,
            query: query
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            guard let me = authenticationBox.authentication.user(in: managedObjectContext) else {
                assertionFailure()
                return
            }
            
            for entity in response.value {
                let result = Persistence.Status.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Status.PersistContext(
                        domain: authenticationBox.domain,
                        entity: entity,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                
                result.status.update(liked: true, by: me)
                result.status.reblog?.update(liked: true, by: me)
            }   // end for … in
        }
        
        return response
    }   // end func
}

extension APIService {
    public func favoritedBy(
        status: MastodonStatus,
        query: Mastodon.API.Statuses.FavoriteByQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let statusID: String = status.reblog?.id ?? status.id

        let response = try await Mastodon.API.Statuses.favoriteBy(
            session: session,
            domain: authenticationBox.domain,
            statusID: statusID,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }   // end func
}
