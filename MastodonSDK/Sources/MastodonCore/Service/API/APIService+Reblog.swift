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
        let rebloggedCount: Int
    }
    
    public func reblog(
        status: Mastodon.Entity.Status,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _status = status.reblog ?? status
        let isReblogged = status.reblogged ?? false
        let rebloggedCount = status.reblogsCount
        let reblogCount = isReblogged ? rebloggedCount - 1 : rebloggedCount + 1
        let reblogContext = MastodonReblogContext(
            statusID: status.id,
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
        status: Mastodon.Entity.Status,
        query: Mastodon.API.Statuses.RebloggedByQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {

        let response = try await Mastodon.API.Statuses.rebloggedBy(
            session: session,
            domain: authenticationBox.domain,
            statusID: status.reblog?.id ?? status.id,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }   // end func
}
