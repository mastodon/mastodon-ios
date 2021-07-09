//
//  Mastodon+API+Account+Filter.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-9.
//

import Foundation
import Combine

// MARK: - Account credentials
extension Mastodon.API.Account {

    static func filtersEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("filters")
    }

    /// View all filters
    ///
    /// Creates a user and account records.
    ///
    /// - Since: 2.4.3
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/7/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/filters/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Filter]` nested in the response
    public static func filters(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Filter]>, Error> {
        let request = Mastodon.API.get(
            url: filtersEndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Filter].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

}
