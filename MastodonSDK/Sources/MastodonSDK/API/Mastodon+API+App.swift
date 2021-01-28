//
//  Mastodon+API+App.swift
//
//
//  Created by xiaojian sun on 2021/1/25.
//

import Foundation
import Combine

extension Mastodon.API.App {

    static func appEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("apps")
    }
    
    public static func create(
        session: URLSession,
        domain: String,
        query: CreateQuery
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Application>, Error>  {
        let request = Mastodon.API.request(
            url: appEndpointURL(domain: domain),
            query: query,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Application.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

}

extension Mastodon.API.App {
    
    public struct CreateQuery: Codable, PostQuery {
        public let clientName: String
        public let redirectURIs: String
        public let scopes: String?
        public let website: String?
        
        enum CodingKeys: String, CodingKey {
            case clientName = "client_name"
            case redirectURIs = "redirect_uris"
            case scopes
            case website
        }
        
        public init(
            clientName: String,
            redirectURIs: String = "urn:ietf:wg:oauth:2.0:oob",
            scopes: String? = "read write follow push",
            website: String?
        ) {
            self.clientName = clientName
            self.redirectURIs = redirectURIs
            self.scopes = scopes
            self.website = website
        }
        
        var body: Data? {
            return try? Mastodon.API.encoder.encode(self)
        }
    }
    
}
