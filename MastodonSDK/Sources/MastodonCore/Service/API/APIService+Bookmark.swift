//
//  APIService+Bookmark.swift
//  Mastodon
//
//  Created by ProtoLimit on 2022/07/28.
//

import Foundation
import Combine
import MastodonSDK
import CoreData
import CoreDataStack

extension APIService {

    private struct MastodonBookmarkContext {
        let statusID: Status.ID
        let isBookmarked: Bool
    }

    public func bookmark(
        record: ManagedObjectRecord<Status>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {

        let managedObjectContext = backgroundManagedObjectContext
        
        // update bookmark state and retrieve bookmark context
        let bookmarkContext: MastodonBookmarkContext = try await managedObjectContext.performChanges {
            let authentication = authenticationBox.authentication
            
            guard
                let _status = record.object(in: managedObjectContext),
                let me = authentication.user(in: managedObjectContext)
            else {
                throw APIError.implicit(.badRequest)
            }

            let status = _status.reblog ?? _status
            let isBookmarked = status.bookmarkedBy.contains(me)
            status.update(bookmarked: !isBookmarked, by: me)
            let context = MastodonBookmarkContext(
                statusID: status.id,
                isBookmarked: isBookmarked
            )
            return context
        }

        // request bookmark or undo bookmark
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>
        do {
            let response = try await Mastodon.API.Bookmarks.bookmarks(
                domain: authenticationBox.domain,
                statusID: bookmarkContext.statusID,
                session: session,
                authorization: authenticationBox.userAuthorization,
                bookmarkKind: bookmarkContext.isBookmarked ? .destroy : .create
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
        
        // update bookmark state
        try await managedObjectContext.performChanges {
            let authentication = authenticationBox.authentication
            
            guard
                let _status = record.object(in: managedObjectContext),
                let me = authentication.user(in: managedObjectContext)
            else { return }
            
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
            case .failure:
                // rollback
                status.update(bookmarked: bookmarkContext.isBookmarked, by: me)
            }
        }
        
        let response = try result.get()
        return response
    }
    
}

extension APIService {
    public func bookmarkedStatuses(
        limit: Int = onceRequestStatusMaxCount,
        maxID: String? = nil,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let query = Mastodon.API.Bookmarks.BookmarkStatusesQuery(limit: limit, minID: nil, maxID: maxID)
        
        let response = try await Mastodon.API.Bookmarks.bookmarkedStatus(
            domain: authenticationBox.domain,
            session: session,
            authorization: authenticationBox.userAuthorization,
            query: query
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            
            guard
                let me = authenticationBox.authentication.user(in: managedObjectContext)
            else {
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
                
                result.status.update(bookmarked: true, by: me)
                result.status.reblog?.update(bookmarked: true, by: me)
            }   // end for … in
        }
        
        return response
    }   // end func
}
