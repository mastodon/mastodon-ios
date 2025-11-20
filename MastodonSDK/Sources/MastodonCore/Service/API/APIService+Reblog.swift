//
//  APIService+Reblog.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-9.
//

import Foundation
import Combine
import MastodonSDK
import CoreData
import CoreDataStack

extension APIService {
    
    private struct MastodonReblogContext {
        let statusID: Status.ID
        let isReblogged: Bool
        let rebloggedCount: Int64
    }
    
    public func reblog(
        status: MastodonStatus,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
       
        // update repost state and retrieve repost context
        let _status = status.reblog ?? status
        let isReblogged = _status.entity.reblogged == true
        let rebloggedCount = Int64(_status.entity.reblogsCount)

        let reblogContext = MastodonReblogContext(
            statusID: _status.id,
            isReblogged: isReblogged,
            rebloggedCount: rebloggedCount
        )
        
        // request repost or undo repost
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>
        do {
            let response = try await Mastodon.API.Reblog.reblog(
                session: session,
                domain: authenticationBox.domain,
                statusID: reblogContext.statusID,
                reblogKind: reblogContext.isReblogged ? .undoReblog : .reblog(query: Mastodon.API.Reblog.ReblogQuery(visibility: .public)),
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
                
        let response = try result.get()
        return response
    }
    
    /// If visibility is nil, will use the account's default visibility
    public func boost(
        boostableStatusId: Mastodon.Entity.Status.ID,
        withVisibility visibility: Mastodon.Entity.Source.Privacy? = nil,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Entity.Status {
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>
        do {
            let defaultVisibility = authenticationBox.authentication.cachedAccount()?.source?.privacy ?? .public
            let response = try await Mastodon.API.Reblog.reblog(
                session: session,
                domain: authenticationBox.domain,
                statusID: boostableStatusId,
                reblogKind: .reblog(query: Mastodon.API.Reblog.ReblogQuery(visibility: visibility ?? defaultVisibility)),
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
        
        let response = try result.get()
        return response.value
    }
    
    public func unboost(
        boostableStatusId: Mastodon.Entity.Status.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Entity.Status {
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>
        do {
            let response = try await Mastodon.API.Reblog.reblog(
                session: session,
                domain: authenticationBox.domain,
                statusID: boostableStatusId,
                reblogKind: .undoReblog,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
        
        let response = try result.get()
        return response.value
    }
}

extension APIService {
    public func boostedBy(
        actionableStatusID: Mastodon.Entity.Status.ID,
        query: Mastodon.API.Statuses.RebloggedByQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let response = try await Mastodon.API.Statuses.boostedBy(
            session: session,
            domain: authenticationBox.domain,
            statusID: actionableStatusID,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }
}
