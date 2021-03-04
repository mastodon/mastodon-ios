//
//  Mastodon+API+Polls.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import Foundation
import Combine

extension Mastodon.API.Polls {
    
    static func viewPollEndpointURL(domain: String, pollID: Mastodon.Entity.Poll.ID) -> URL {
        let pathComponent = "polls/" + pollID
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    static func votePollEndpointURL(domain: String, pollID: Mastodon.Entity.Poll.ID) -> URL {
        let pathComponent = "polls/" + pollID + "/votes"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
 
    /// View a poll
    ///
    /// Using this endpoint to view the poll of status
    ///
    /// - Since: 2.8.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/3
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/polls/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - pollID: id for poll
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Poll` nested in the response
    public static func poll(
        session: URLSession,
        domain: String,
        pollID: Mastodon.Entity.Poll.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error>  {
        let request = Mastodon.API.get(
            url: viewPollEndpointURL(domain: domain, pollID: pollID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Poll.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Vote on a poll
    ///
    /// Using this endpoint to vote an option of poll
    ///
    /// - Since: 2.8.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/4
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/polls/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - pollID: id for poll
    ///   - query: `VoteQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Poll` nested in the response
    public static func vote(
        session: URLSession,
        domain: String,
        pollID: Mastodon.Entity.Poll.ID,
        query: VoteQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error>  {
        let request = Mastodon.API.post(
            url: votePollEndpointURL(domain: domain, pollID: pollID),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Poll.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Polls {
    public struct VoteQuery: Codable, PostQuery {
        public let choices: [Int]
        
        public init(choices: [Int]) {
            self.choices = choices
        }
    }
}
