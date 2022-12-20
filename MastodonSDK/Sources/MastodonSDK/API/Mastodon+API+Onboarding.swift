//
//  Mastodon+API+Onboarding.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-18.
//

import Foundation
import Combine

extension Mastodon.API.Onboarding {
    
    static let serversEndpointURL = Mastodon.API.joinMastodonEndpointURL.appendingPathComponent("servers")
    static let categoriesEndpointURL = Mastodon.API.joinMastodonEndpointURL.appendingPathComponent("categories")
    static let languagesEndpointURL = Mastodon.API.joinMastodonEndpointURL.appendingPathComponent("languages")
 
    /// Fetch server list
    ///
    /// Using this endpoint to fetch booked servers
    ///
    /// # Last Update
    ///   2021/2/19
    /// # Reference
    ///   undocumented
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - query: `ServerQuery`
    /// - Returns: `AnyPublisher` contains `Server` nested in the response
    public static func servers(
        session: URLSession,
        query: ServersQuery
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Server]>, Error>  {
        let request = Mastodon.API.get(
            url: serversEndpointURL,
            query: query,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Server].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetch server categories
    ///
    /// Using this endpoint to fetch booked categories
    ///
    /// # Last Update
    ///   2021/2/19
    /// # Reference
    ///   undocumented
    /// - Parameters:
    ///   - session: `URLSession`
    /// - Returns: `AnyPublisher` contains `Category` nested in the response
    public static func categories(
        session: URLSession
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Category]>, Error>  {
        let request = Mastodon.API.get(
            url: categoriesEndpointURL,
            query: nil,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Category].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    /// Fetch server languages
    ///
    /// Using this endpoint to fetch booked languages
    ///
    /// # Last Update
    ///   2022/12/19
    /// # Reference
    ///   undocumented
    /// - Parameters:
    ///   - session: `URLSession`
    /// - Returns: `AnyPublisher` contains `Language` nested in the response
    public static func languages(
        session: URLSession
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Language]>, Error>  {
        let request = Mastodon.API.get(
            url: languagesEndpointURL,
            query: nil,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Language].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Mastodon.API.Onboarding {

    public struct ServersQuery: GetQuery {
        public let language: String?
        public let category: String?
        
        public init(language: String?, category: String?) {
            self.language = language
            self.category = category
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            language.flatMap { items.append(URLQueryItem(name: "language", value: $0)) }
            category.flatMap { items.append(URLQueryItem(name: "category", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
