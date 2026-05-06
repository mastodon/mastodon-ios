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

    static func filtersV1EndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("filters")
    }
    
    static func filtersV2EndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("filters")
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
    ) async throws -> [Mastodon.Entity.FilterInfo] {
        let v2request = Mastodon.API.get(
            url: filtersV2EndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )

        do {
            RateLimitViewModel.shared.didMakeRequest("filters")
            let (data, response) = try await session.data(for: v2request)
            let value = try Mastodon.API.decode(type: [Mastodon.Entity.FilterV2].self, from: data, response: response)
            return value
        } catch let error {
            guard let apiError = error as? Mastodon.API.Error, apiError.httpResponseStatus == .notFound else { throw error }
        }
        
        // fallback to v1
        let v1request = Mastodon.API.get(
            url: filtersV1EndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("filters fallback")
        let (data, response) = try await session.data(for: v1request)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.FilterV1].self, from: data, response: response)
        return value
    }
}
