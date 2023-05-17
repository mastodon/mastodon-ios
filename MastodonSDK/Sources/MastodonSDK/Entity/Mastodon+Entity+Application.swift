//
//  Mastodon+Entity+Application.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Application
    ///
    /// - Since: 0.9.9
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/application/)
    public struct Application: Codable, Sendable {

        public let name: String

        public let website: String?
        public let vapidKey: String?
        
        // Client
        public let redirectURI: String?      // undocumented
        public let clientID: String?
        public let clientSecret: String?

        public init(name: String, website: String?, vapidKey: String?, redirectURI: String?, clientID: String?, clientSecret: String?) {
            self.name = name
            self.website = website
            self.vapidKey = vapidKey
            self.redirectURI = redirectURI
            self.clientID = clientID
            self.clientSecret = clientSecret
        }
        
        enum CodingKeys: String, CodingKey {
            case name
            case website
            case vapidKey = "vapid_key"
            case redirectURI = "redirect_uri"
            case clientID = "client_id"
            case clientSecret = "client_secret"
        }
    }
}
