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
        let statusID: Status.ID
        let isFavorited: Bool
        let favoritedCount: Int
    }
    
    public func favorite(
        status: Mastodon.Entity.Status,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let authentication = authenticationBox.authentication
        let me = authentication.user

        let _status = status.reblog ?? status
        let isFavorited = status.favourited ?? false
        let favoritedCount = status.favouritesCount
        let favoriteContext = MastodonFavoriteContext(
            statusID: status.id,
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

        return response
    }   // end func
}

extension APIService {
    public func favoritedBy(
        status: Mastodon.Entity.Status,
        query: Mastodon.API.Statuses.FavoriteByQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let response = try await Mastodon.API.Statuses.favoriteBy(
            session: session,
            domain: authenticationBox.domain,
            statusID: status.reblog?.id ?? status.id,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }   // end func
}
