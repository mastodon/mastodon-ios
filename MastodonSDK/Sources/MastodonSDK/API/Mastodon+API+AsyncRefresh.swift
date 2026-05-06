//
//  Mastodon+API+AsyncRefresh.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/21/25.
//
import Combine
import Foundation

enum AsyncRefreshError: Error {
    case error(String?)
}

extension Mastodon.API.AsyncRefresh {
    static func asyncRefreshUpdateEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointV1BetaURL(domain: domain).appendingPathComponent("async_refreshes")
    }
    
    /// AsyncRefresh
    ///
    /// Use this endpoint to get an updated information about an ongoing AsyncRefresh operation
    ///
    /// - Since: 4.5
    /// - Version: 4.5
    /// # Last Update
    ///   2025/11/21
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/async_refreshes/)
    /// - Parameters:
    ///   - asyncRefreshID: id of the ongoing AsyncRefresh query you want to check.  This comes from an AsyncRefresh header returned with a previous API query response as an AsyncRefreshAvailable object.
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `AsyncRefresh` nested in the response
    public static func updatedAsyncRefresh(
        domain: String,
        asyncRefreshID: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization,
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.AsyncRefresh>, Error> {
        let url = asyncRefreshUpdateEndpointURL(domain: domain).appendingPathComponent(asyncRefreshID)
        let request = Mastodon.API.get(url: url, authorization: authorization)
        RateLimitViewModel.shared.didMakeRequest("update async refresh operation \(asyncRefreshID)")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.AsyncRefreshResult.self, from: data, response: response)
                if let result = value.result {
                    return Mastodon.Response.Content(value: result, response: response)
                } else {
                    throw AsyncRefreshError.error(value.errorString)
                }
            }
            .eraseToAnyPublisher()
    }
}
