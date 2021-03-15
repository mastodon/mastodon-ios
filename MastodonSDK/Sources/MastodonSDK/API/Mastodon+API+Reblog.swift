//
//  Mastodon+API+Status+Reblog.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-9.
//

import Foundation
import Combine

extension Mastodon.API.Reblog {
 
    static func rebloggedByEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        let pathComponent = "statuses/" + statusID + "/reblogged_by"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Boosted by
    ///
    /// View who boosted a given status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/15
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func rebloggedBy(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.get(
            url: rebloggedByEndpointURL(domain: domain, statusID: statusID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Reblog {
 
    static func reblogEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        let pathComponent = "statuses/" + statusID + "/reblog"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Boost
    ///
    /// Reshare a status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/15
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func reblog(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        query: ReblogQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.post(
            url: reblogEndpointURL(domain: domain, statusID: statusID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public typealias Visibility = Mastodon.Entity.Source.Privacy
    
    public struct ReblogQuery: Codable, PostQuery {
        public let visibility: Visibility?
        
        public init(visibility: Visibility?) {
            self.visibility = visibility
        }
    }
    
}

extension Mastodon.API.Reblog {
 
    static func unreblogEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        let pathComponent = "statuses/" + statusID + "/unreblog"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Undo reblog
    ///
    /// Undo a reshare of a status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func undoReblog(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.post(
            url: unreblogEndpointURL(domain: domain, statusID: statusID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Reblog {
    
    public enum ReblogKind {
        case reblog(query: ReblogQuery)
        case undoReblog
    }
    
    public static func reblog(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        reblogKind: ReblogKind,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        switch reblogKind {
        case .reblog(let query):
            return reblog(session: session, domain: domain, statusID: statusID, query: query, authorization: authorization)
        case .undoReblog:
            return undoReblog(session: session, domain: domain, statusID: statusID, authorization: authorization)
        }
    }
    
}
