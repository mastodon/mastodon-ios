//
//  Mastodon+API+Account.swift
//  
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine

extension Mastodon.API.Account {
    
    static func verifyCredentialsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/verify_credentials") 
    }
    static func accountsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts")
    }
    static func updateCredentialsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/update_credentials")
    }

    /// Test to make sure that the user token works.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: App token
    /// - Returns: `AnyPublisher` contains `Account` nested in the response
    public static func verifyCredentials(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let request = Mastodon.API.get(
            url: verifyCredentialsEndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Account.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    /// Creates a user and account records.
    ///
    /// - Since: 2.7.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `RegisterQuery` with account registration information
    ///   - authorization: App token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func register(
        session: URLSession,
        domain: String,
        query: RegisterQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> {
        let request = Mastodon.API.post(
            url: accountsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Token.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    /// Update the user's display and preferences.
    ///
    /// - Since: 1.1.1
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `CredentialQuery` with update credential information
    ///   - authorization: `UpdateCredentialQuery` with update information
    /// - Returns: `AnyPublisher` contains updated `Account` nested in the response
    public static func updateCredentials(
        session: URLSession,
        domain: String,
        query: UpdateCredentialQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let request = Mastodon.API.patch(
            url: updateCredentialsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Account.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    /// View information about a profile.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccountInfoQuery` with account query information,
    ///   - authorization: user token
    /// - Returns: `AnyPublisher` contains `Account` nested in the response
    public static func accountInfo(
        session: URLSession,
        domain: String,
        query: AccountInfoQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let request = Mastodon.API.get(
            url: accountsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Account.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Account {
    
    public struct RegisterQuery: Codable, PostQuery {
        public let reason: String?
        public let username: String
        public let email: String
        public let password: String
        public let agreement: Bool
        public let locale: String
        
        public init(reason: String? = nil, username: String, email: String, password: String, agreement: Bool, locale: String) {
            self.reason = reason
            self.username = username
            self.email = email
            self.password = password
            self.agreement = agreement
            self.locale = locale
        }
    }

    public struct UpdateCredentialQuery: Codable, PatchQuery {

        public var discoverable: Bool?
        public var bot: Bool?
        public var displayName: String?
        public var note: String?
        public var avatar: String?
        public var header: String?
        public var locked: Bool?
        public var source: Mastodon.Entity.Source?
        public var fieldsAttributes: [Mastodon.Entity.Field]?

        enum CodingKeys: String, CodingKey {
            case discoverable
            case bot
            case displayName = "display_name"
            case note

            case avatar
            case header
            case locked
            case source
            case fieldsAttributes = "fields_attributes"
        }

        public init(
            discoverable: Bool? = nil,
            bot: Bool? = nil,
            displayName: String? = nil,
            note: String? = nil,
            avatar: Mastodon.Entity.MediaAttachment? = nil,
            header: Mastodon.Entity.MediaAttachment? = nil,
            locked: Bool? = nil,
            source: Mastodon.Entity.Source? = nil,
            fieldsAttributes: [Mastodon.Entity.Field]? = nil
        ) {
            self.discoverable = discoverable
            self.bot = bot
            self.displayName = displayName
            self.note = note
            self.avatar = avatar?.base64EncondedString
            self.header = header?.base64EncondedString
            self.locked = locked
            self.source = source
            self.fieldsAttributes = fieldsAttributes
        }
    }

    public struct AccountInfoQuery: Codable, GetQuery {

        public let id: String

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "id", value: id))
            return items
        }
    }
}
