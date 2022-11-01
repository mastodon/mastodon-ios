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
import CommonOSLog

extension APIService {
    
    private struct MastodonFavoriteContext {
        let statusID: Status.ID
        let isFavorited: Bool
        let favoritedCount: Int64
    }
    
    public func favorite(
        record: ManagedObjectRecord<Status>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let logger = Logger(subsystem: "APIService", category: "Favorite")
        
        let managedObjectContext = backgroundManagedObjectContext
        
        // update like state and retrieve like context
        let favoriteContext: MastodonFavoriteContext = try await managedObjectContext.performChanges {
            guard let authentication = authenticationBox.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else {
                throw APIError.implicit(.badRequest)
            }
            let me = authentication.user
            let status = _status.reblog ?? _status
            let isFavorited = status.favouritedBy.contains(me)
            let favoritedCount = status.favouritesCount
            let favoriteCount = isFavorited ? favoritedCount - 1 : favoritedCount + 1
            status.update(liked: !isFavorited, by: me)
            status.update(favouritesCount: favoriteCount)
            let context = MastodonFavoriteContext(
                statusID: status.id,
                isFavorited: isFavorited,
                favoritedCount: favoritedCount
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status favorite: \(!isFavorited), \(favoriteCount)")
            return context
        }

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
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update favorite failure: \(error.localizedDescription)")
        }
        
        // update like state
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationBox.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            let status = _status.reblog ?? _status
            
            switch result {
            case .success(let response):
                _ = Persistence.Status.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Status.PersistContext(
                        domain: authenticationBox.domain,
                        entity: response.value,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                if favoriteContext.isFavorited {
                    status.update(favouritesCount: max(0, status.favouritesCount - 1))  // undo API return count has delay. Needs -1 local
                }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status favorite: \(response.value.favourited.debugDescription)")
            case .failure:
                // rollback
                status.update(liked: favoriteContext.isFavorited, by: me)
                status.update(favouritesCount: favoriteContext.favoritedCount)
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): rollback status favorite")
            }
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
            guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else {
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
        status: ManagedObjectRecord<Status>,
        query: Mastodon.API.Statuses.FavoriteByQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let managedObjectContext = backgroundManagedObjectContext
        let _statusID: Status.ID? = try? await managedObjectContext.perform {
            guard let _status = status.object(in: managedObjectContext) else { return nil }
            let status = _status.reblog ?? _status
            return status.id
        }
        guard let statusID = _statusID else {
            throw APIError.implicit(.badRequest)
        }

        let response = try await Mastodon.API.Statuses.favoriteBy(
            session: session,
            domain: authenticationBox.domain,
            statusID: statusID,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        try await managedObjectContext.performChanges {
            for entity in response.value {
                _ = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: .init(
                        domain: authenticationBox.domain,
                        entity: entity,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in
        }
        
        return response
    }   // end func
}
