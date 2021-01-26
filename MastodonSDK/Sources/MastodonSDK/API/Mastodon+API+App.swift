//
//  Mastodon+API+App.swift
//
//
//  Created by xiaojian sun on 2021/1/25.
//

import Combine
import Foundation

public extension Mastodon.API.App {
    internal static let appEndpointURL = Mastodon.API.endpointURL.appendingPathComponent("apps")
    
    struct OAuth2Credentials: Codable {
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
    
    struct registerAppQuery {
        public let client_name: String
        public let redirect_uris: String
        public let scopes: String
        public let website: String
        
        public init(client_name: String, redirect_uris: String, scopes: String, website: String) {
            self.client_name = client_name
            self.redirect_uris = redirect_uris
            self.scopes = scopes
            self.website = website
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "client_name", value: client_name))
            items.append(URLQueryItem(name: "redirect_uris", value: redirect_uris))
            items.append(URLQueryItem(name: "scopes", value: scopes))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}

extension Mastodon.API.App.OAuth2Credentials: Equatable {}
