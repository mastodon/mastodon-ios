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
import CommonOSLog

extension APIService {
    
    private struct MastodonReblogContext {
        let statusID: Status.ID
        let isReblogged: Bool
        let rebloggedCount: Int64
    }
    
    public func reblog(
        record: ManagedObjectRecord<Status>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let logger = Logger(subsystem: "APIService", category: "Reblog")
        let managedObjectContext = backgroundManagedObjectContext
        
        // update repost state and retrieve repost context
        let _reblogContext: MastodonReblogContext? = try await managedObjectContext.performChanges {
            guard let authentication = authenticationBox.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else { return nil }
            
            let me = authentication.user
            let status = _status.reblog ?? _status
            let isReblogged = status.rebloggedBy.contains(me)
            let rebloggedCount = status.reblogsCount
            let reblogCount = isReblogged ? rebloggedCount - 1 : rebloggedCount + 1
            status.update(reblogged: !isReblogged, by: me)
            status.update(reblogsCount: Int64(max(0, reblogCount)))
            let reblogContext = MastodonReblogContext(
                statusID: status.id,
                isReblogged: isReblogged,
                rebloggedCount: rebloggedCount
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status reblog: \(!isReblogged), \(reblogCount)")
            return reblogContext
        }
        guard let reblogContext = _reblogContext else {
            throw APIError.implicit(.badRequest)
        }
        
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
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update reblog failure: \(error.localizedDescription)")
        }
        
        // update repost state
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
                        domain: authentication.domain,
                        entity: response.value,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                if reblogContext.isReblogged {
                    status.update(reblogsCount: max(0, status.reblogsCount - 1))        // undo API return count has delay. Needs -1 local
                }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status reblog: \(!reblogContext.isReblogged)")
            case .failure:
                // rollback
                status.update(reblogged: reblogContext.isReblogged, by: me)
                status.update(reblogsCount: reblogContext.rebloggedCount)
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): rollback status reblog")
            }
        }
        
        let response = try result.get()
        return response
    }

}

extension APIService {
    public func rebloggedBy(
        status: ManagedObjectRecord<Status>,
        query: Mastodon.API.Statuses.RebloggedByQuery,
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
