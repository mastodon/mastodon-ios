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
        status: Mastodon.Entity.Status,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let authentication = authenticationBox.authentication
        let me = authentication.user
        
        let isBookmarked = try await Mastodon.API.Bookmarks.bookmarkedStatus(
            domain: authenticationBox.domain,
            session: session,
            authorization: authenticationBox.userAuthorization,
            query: .init()
        ).singleOutput().value.contains(where: { $0.id == status.id }) // TODO: CD is this sufficient? Do we need to check the domain as well?

        let bookmarkContext = MastodonBookmarkContext(
            statusID: status.id,
            isBookmarked: isBookmarked
        )

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

        return response
    }   // end func
}
