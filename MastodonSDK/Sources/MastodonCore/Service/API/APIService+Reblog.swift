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

}

extension APIService {
    public func rebloggedBy(
        status: MastodonStatus,
        query: Mastodon.API.Statuses.RebloggedByQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let managedObjectContext = backgroundManagedObjectContext
        let statusID: Status.ID = status.reblog?.id ?? status.id

        let response = try await Mastodon.API.Statuses.rebloggedBy(
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
