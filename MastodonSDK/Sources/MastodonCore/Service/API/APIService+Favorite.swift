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
        let statusID: Mastodon.Entity.Status.ID
        let isFavorited: Bool
        let favoritedCount: Int64
    }
    
    public func favorite(
        record: Mastodon.Entity.Status,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {

//        let managedObjectContext = backgroundManagedObjectContext
        
        // update like state and retrieve like context
//        let favoriteContext: MastodonFavoriteContext = try await managedObjectContext.performChanges {
//            let authentication = authenticationBox.authentication
//            
//            guard
//                let _status = record.object(in: managedObjectContext),
//                let me = authentication.user(in: managedObjectContext)
//            else {
//                throw APIError.implicit(.badRequest)
//            }

            let status = record.reblog ?? record
//            let isFavorited = status.favouritedBy.contains(me)
//            let favoritedCount = status.favouritesCount
//            let favoriteCount = isFavorited ? favoritedCount - 1 : favoritedCount + 1
//            status.update(liked: !isFavorited, by: me)
//            status.update(favouritesCount: favoriteCount)
//            let context = MastodonFavoriteContext(
//                statusID: status.id,
//                isFavorited: isFavorited,
//                favoritedCount: favoritedCount
//            )
//            return context
//        }

        // request like or undo like
//        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>
//        do {
//            let response = try await Mastodon.API.Favorites.favorites(
//                domain: authenticationBox.domain,
//                statusID: status.id,
//                session: session,
//                authorization: authenticationBox.userAuthorization,
//                favoriteKind: status.favourited == true ? .destroy : .create
//            ).singleOutput()
//            result = .success(response)
//        } catch {
//            result = .failure(error)
//        }
        
        let response = try await Mastodon.API.Favorites.favorites(
            domain: authenticationBox.domain,
            statusID: status.id,
            session: session,
            authorization: authenticationBox.userAuthorization,
            favoriteKind: status.favourited == true ? .destroy : .create
        ).singleOutput()
        
//        // update like state
//        try await managedObjectContext.performChanges {
//            let authentication = authenticationBox.authentication
//            
//            guard
//                let _status = record.object(in: managedObjectContext),
//                let me = authentication.user(in: managedObjectContext)
//            else { return }
//
//            let status = _status.reblog ?? _status
//            
//            switch result {
//            case .success(let response):
//                _ = Persistence.Status.createOrMerge(
//                    in: managedObjectContext,
//                    context: Persistence.Status.PersistContext(
//                        domain: authenticationBox.domain,
//                        entity: response.value,
//                        me: me,
//                        statusCache: nil,
//                        userCache: nil,
//                        networkDate: response.networkDate
//                    )
//                )
//                if favoriteContext.isFavorited {
//                    status.update(favouritesCount: max(0, status.favouritesCount - 1))  // undo API return count has delay. Needs -1 local
//                }
//            case .failure:
//                // rollback
//                status.update(liked: favoriteContext.isFavorited, by: me)
//                status.update(favouritesCount: favoriteContext.favoritedCount)
//            }
//        }
        
//        let response = try result.get()
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
        
//        let managedObjectContext = self.backgroundManagedObjectContext
//        try await managedObjectContext.performChanges {
//            guard let me = authenticationBox.authentication.user(in: managedObjectContext) else {
//                assertionFailure()
//                return
//            }
//            
//            for entity in response.value {
//                let result = Persistence.Status.createOrMerge(
//                    in: managedObjectContext,
//                    context: Persistence.Status.PersistContext(
//                        domain: authenticationBox.domain,
//                        entity: entity,
//                        me: me,
//                        statusCache: nil,
//                        userCache: nil,
//                        networkDate: response.networkDate
//                    )
//                )
//                
//                result.status.update(liked: true, by: me)
//                result.status.reblog?.update(liked: true, by: me)
//            }   // end for … in
//        }
        
        return response
    }   // end func
}

extension APIService {
    public func favoritedBy(
        status: Mastodon.Entity.Status,
        query: Mastodon.API.Statuses.FavoriteByQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
//        let managedObjectContext = backgroundManagedObjectContext
//        let _statusID: Status.ID? = try? await managedObjectContext.perform {
//            guard let _status = status.object(in: managedObjectContext) else { return nil }
            let _status = status.reblog ?? status
//            return status.id
//        }
//        guard let statusID = _statusID else {
//            throw APIError.implicit(.badRequest)
//        }

        let response = try await Mastodon.API.Statuses.favoriteBy(
            session: session,
            domain: authenticationBox.domain,
            statusID: _status.id,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
//        try await managedObjectContext.performChanges {
//            for entity in response.value {
//                _ = Persistence.MastodonUser.createOrMerge(
//                    in: managedObjectContext,
//                    context: .init(
//                        domain: authenticationBox.domain,
//                        entity: entity,
//                        cache: nil,
//                        networkDate: response.networkDate
//                    )
//                )
//            }   // end for … in
//        }
        
        return response
    }   // end func
}
