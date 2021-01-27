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
        query: CreateQuery
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.API.App.Application>, Error>  {
        fatalError()
    }
    

}

extension Mastodon.API.App {
    
    struct Application: Codable {

        public let id: String

        public let name: String
        public let website: String?
        public let redirectURI: String
        public let clientID: String
        public let clientSecret: String
        public let vapidKey: String
        
        enum CodingKeys: String, CodingKey {
            case id
          
            case name
            case website
            case redirectURI = "redirect_uri"
            case clientID = "client_id"
            case clientSecret = "client_secret"
            case vapidKey = "vapid_key"
        }
    }
    
    struct CreateQuery {
        public let clientName: String
        public let redirectURIs: String
        public let scopes: String?
        public let website: String?
        
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
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "client_name", value: clientName))
            items.append(URLQueryItem(name: "redirect_uris", value: redirectURIs))
            scopes.flatMap {
                items.append(URLQueryItem(name: "scopes", value: $0))
            }
            website.flatMap {
                items.append(URLQueryItem(name: "website", value: $0))
            }
            
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
