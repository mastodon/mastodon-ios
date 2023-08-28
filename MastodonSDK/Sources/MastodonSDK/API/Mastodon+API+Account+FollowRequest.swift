//
//  Mastodon+API+Account+FollowRequest.swift
//  
//
//  Created by sxiaojian on 2021/4/27.
//

import Foundation
import Combine

// MARK: - Account credentials
extension Mastodon.API.Account {

    static func pendingFollowRequestEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("follow_requests")
    }
    
    static func acceptFollowRequestEndpointURL(domain: String, userID: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("follow_requests")
            .appendingPathComponent(userID)
            .appendingPathComponent("authorize")
    }
    
    static func rejectFollowRequestEndpointURL(domain: String, userID: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("follow_requests")
            .appendingPathComponent(userID)
            .appendingPathComponent("reject")
    }

    /// Pending Follow Requests
    ///
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/follow_requests/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - userID: ID of the account in the database
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Account]` nested in the response
    public static func pendingFollowRequest(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let request = Mastodon.API.get(
            url: pendingFollowRequestEndpointURL(domain: domain),
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }


    /// Accept Follow
    ///
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/follow_requests/#allow)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - userID: ID of the account in the database
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func acceptFollowRequest(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        let request = Mastodon.API.post(
            url: acceptFollowRequestEndpointURL(domain: domain, userID: userID),
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
    
    /// Reject Follow
    ///
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/follow_requests/#reject)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - userID: ID of the account in the database
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func rejectFollowRequest(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        let request = Mastodon.API.post(
            url: rejectFollowRequestEndpointURL(domain: domain, userID: userID),
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
 
    public enum FollowRequestQuery {
        case accept
        case reject
    }
    
    public static func followRequest(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        query: FollowRequestQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        switch query {
        case .accept:
            return acceptFollowRequest(
                session: session,
                domain: domain,
                userID: userID,
                authorization: authorization
            )
        case .reject:
            return rejectFollowRequest(
                session: session,
                domain: domain,
                userID: userID,
                authorization: authorization
            )
        }   // end switch
    }
    
}
