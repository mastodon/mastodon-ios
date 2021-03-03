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
 
    /// View a poll
    ///
    /// Using this endpoint to view the poll of status
    ///
    /// # Last Update
    ///   2021/3/3
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/polls/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - pollID: id for poll
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Server` nested in the response
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
    
}
