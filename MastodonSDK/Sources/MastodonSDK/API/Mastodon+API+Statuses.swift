//
//  Mastodon+API+Statuses.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import Foundation
import Combine

extension Mastodon.API.Statuses {
    
    static func viewStatusEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        let pathComponent = "statuses/" + statusID
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
 
    /// View specific status
    ///
    /// View information about a status
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/10
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func status(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Poll.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.get(
            url: viewStatusEndpointURL(domain: domain, statusID: statusID),
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
