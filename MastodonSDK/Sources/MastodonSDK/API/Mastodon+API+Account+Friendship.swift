//
//  Mastodon+API+Account+Friendship.swift
//  
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import Foundation
import Combine

extension Mastodon.API.Account {
    
    static func accountsRelationshipsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/relationships")
    }

    /// Check relationships to other accounts
    ///
    /// Find out whether a given account is followed, blocked, muted, etc.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/#perform-actions-on-an-account/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `RelationshipQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Relationship]` nested in the response
    public static func relationships(
        session: URLSession,
        domain: String,
        query: RelationshipQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Relationship]>, Error> {
        let request = Mastodon.API.get(
            url: accountsRelationshipsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Relationship].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct RelationshipQuery: GetQuery {
        public let ids: [Mastodon.Entity.Account.ID]
        
        public init(ids: [Mastodon.Entity.Account.ID]) {
            self.ids = ids
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            for id in ids {
                items.append(URLQueryItem(name: "id[]", value: id))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}

extension Mastodon.API.Account {

    public enum FollowQueryType {
        case follow(query: FollowQuery)
        case unfollow
    }
    
    public static func follow(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        followQueryType: FollowQueryType,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        switch followQueryType {
        case .follow(let query):
            return follow(session: session, domain: domain, accountID: accountID, query: query, authorization: authorization)
        case .unfollow:
            return unfollow(session: session, domain: domain, accountID: accountID, authorization: authorization)
        }
    }

}

extension Mastodon.API.Account {
 
    static func followEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/follow"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Follow
    ///
    /// Follow the given account. Can also be used to update whether to show reblogs or enable notifications.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func follow(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        query: FollowQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let request = Mastodon.API.post(
            url: followEndpointURL(domain: domain, accountID: accountID),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct FollowQuery: Codable, PostQuery {
        public let reblogs: Bool?
        public let notify: Bool?
        
        public init(reblogs: Bool? = nil , notify: Bool? = nil) {
            self.reblogs = reblogs
            self.notify = notify
        }
    }
    
}

extension Mastodon.API.Account {
 
    static func unfollowEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/unfollow"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Unfollow
    ///
    /// Unfollow the given account.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func unfollow(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let request = Mastodon.API.post(
            url: unfollowEndpointURL(domain: domain, accountID: accountID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Account {

    public enum BlockQueryType {
        case block
        case unblock
    }
    
    public static func block(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        blockQueryType: BlockQueryType,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        switch blockQueryType {
        case .block:
            return block(session: session, domain: domain, accountID: accountID, authorization: authorization)
        case .unblock:
            return unblock(session: session, domain: domain, accountID: accountID, authorization: authorization)
        }
    }

}

public extension Mastodon.API.Account {
 
    static func blocksEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("blocks")
    }
    
    /// Block
    ///
    /// Block the given account. Clients should filter statuses from this account if received (e.g. due to a boost in the Home timeline).
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/blocks/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    static func blocks(
        session: URLSession,
        domain: String,
        sinceID: Mastodon.Entity.Status.ID?,
        limit: Int?,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error>  {
        let request = Mastodon.API.get(
            url: blocksEndpointURL(domain: domain),
            query: BlocksQuery(sinceID: sinceID, limit: limit),
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    private struct BlocksQuery: GetQuery {
        private let sinceID: Mastodon.Entity.Status.ID?
        private let limit: Int?

        public init(
            sinceID: Mastodon.Entity.Status.ID?,
            limit: Int?
        ) {
            self.sinceID = sinceID
            self.limit = limit
        }

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}

extension Mastodon.API.Account {
 
    static func blockEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/block"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Block
    ///
    /// Block the given account. Clients should filter statuses from this account if received (e.g. due to a boost in the Home timeline).
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func block(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let request = Mastodon.API.post(
            url: blockEndpointURL(domain: domain, accountID: accountID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Account {
 
    static func unblockEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/unblock"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Unblock
    ///
    /// Unblock the given account.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func unblock(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let request = Mastodon.API.post(
            url: unblockEndpointURL(domain: domain, accountID: accountID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Account {

    public enum MuteQueryType {
        case mute
        case unmute
    }
    
    public static func mute(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        muteQueryType: MuteQueryType,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        switch muteQueryType {
        case .mute:
            return mute(session: session, domain: domain, accountID: accountID, authorization: authorization)
        case .unmute:
            return unmute(session: session, domain: domain, accountID: accountID, authorization: authorization)
        }
    }

}

extension Mastodon.API.Account {
 
    static func mutekEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/mute"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Mute
    ///
    /// Mute the given account. Clients should filter statuses and notifications from this account, if received (e.g. due to a boost in the Home timeline).
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func mute(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let request = Mastodon.API.post(
            url: mutekEndpointURL(domain: domain, accountID: accountID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Account {
 
    static func unmutekEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/unmute"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Unmute
    ///
    /// Unmute the given account.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func unmute(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let request = Mastodon.API.post(
            url: unmutekEndpointURL(domain: domain, accountID: accountID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Account {
    
       static func mutesEndpointURL(
        domain: String
       ) -> URL {
           return Mastodon.API.endpointURL(domain: domain)
               .appendingPathComponent("mutes")
       }
       
       /// View all mutes
       ///
       /// View your mutes. See also accounts/:id/{mute,unmute}.
       ///
       /// - Since: 0.0.0
       /// - Version: 3.3.0
       /// # Last Update
       ///   2021/4/1
       /// # Reference
       ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
       /// - Parameters:
       ///   - session: `URLSession`
       ///   - domain: Mastodon instance domain. e.g. "example.com"
       ///   - accountID: id for account
       ///   - authorization: User token.
       /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
       public static func mutes(
           session: URLSession,
           domain: String,
           sinceID: Mastodon.Entity.Status.ID? = nil,
           limit: Int?,
           authorization: Mastodon.API.OAuth.Authorization
       ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error>  {
           let request = Mastodon.API.get(
                url: mutesEndpointURL(domain: domain),
                query: MutesQuery(sinceID: sinceID, limit: limit),
                authorization: authorization
           )
           return session.dataTaskPublisher(for: request)
               .tryMap { data, response in
                   let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
                   return Mastodon.Response.Content(value: value, response: response)
               }
               .eraseToAnyPublisher()
           
           struct MutesQuery: GetQuery {
               private let sinceID: Mastodon.Entity.Status.ID?
               private let limit: Int?

               public init(
                   sinceID: Mastodon.Entity.Status.ID?,
                   limit: Int?
               ) {
                   self.sinceID = sinceID
                   self.limit = limit
               }

               var queryItems: [URLQueryItem]? {
                   var items: [URLQueryItem] = []
                   sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
                   limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
                   guard !items.isEmpty else { return nil }
                   return items
               }
           }
       }
}
