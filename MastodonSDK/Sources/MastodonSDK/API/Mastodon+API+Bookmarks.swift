//
//  Mastodon+API+Bookmarks.swift
//  
//
//  Created by ProtoLimit on 2022/07/28.
//

import Combine
import Foundation

extension Mastodon.API.Bookmarks {
    
    static func bookmarksStatusesEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("bookmarks")
    }
    
    /// Bookmarked statuses
    ///
    /// Using this endpoint to view the bookmarked list for user
    ///
    /// - Since: 3.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2022/7/28
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/bookmarks/)
    /// - Parameters:
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Server` nested in the response
    public static func bookmarkedStatus(
        domain: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization,
        query: Mastodon.API.Bookmarks.BookmarkStatusesQuery
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> {
        let url = bookmarksStatusesEndpointURL(domain: domain)
        let request = Mastodon.API.get(url: url, query: query, authorization: authorization)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct BookmarkStatusesQuery: GetQuery, PagedQueryType {
        
        public var limit: Int?
        public var minID: String?
        public var maxID: String?
        public var sinceID: Mastodon.Entity.Status.ID?
        
        public init(limit: Int? = nil, minID: String? = nil, maxID: String? = nil, sinceID: String? = nil) {
            self.limit = limit
            self.minID = minID
            self.maxID = maxID
            self.sinceID = sinceID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            if let limit = self.limit {
                items.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if let minID = self.minID {
                items.append(URLQueryItem(name: "min_id", value: minID))
            }
            if let maxID = self.maxID {
                items.append(URLQueryItem(name: "max_id", value: maxID))
            }
            if let sinceID = self.sinceID {
                items.append(URLQueryItem(name: "since_id", value: sinceID))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }

}

extension Mastodon.API.Bookmarks {
    
    static func bookmarkActionEndpointURL(domain: String, statusID: String, bookmarkKind: BookmarkKind) -> URL {
        var actionString: String
        switch bookmarkKind {
        case .create:
            actionString = "/bookmark"
        case .destroy:
            actionString = "/unbookmark"
        }
        let pathComponent = "statuses/" + statusID + actionString
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Bookmark / Undo Bookmark
    ///
    /// Add a status to your bookmarks list / Remove a status from your bookmarks list
    ///
    /// - Since: 3.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2022/7/28
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: Mastodon status id
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Server` nested in the response
    public static func bookmarks(
        domain: String,
        statusID: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization,
        bookmarkKind: BookmarkKind
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let url: URL = bookmarkActionEndpointURL(domain: domain, statusID: statusID, bookmarkKind: bookmarkKind)
        var request = Mastodon.API.post(url: url, query: nil, authorization: authorization)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    public enum BookmarkKind {
        case create
        case destroy
    }

}
