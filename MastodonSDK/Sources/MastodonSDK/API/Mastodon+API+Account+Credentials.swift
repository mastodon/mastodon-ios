//
//  Mastodon+API+Account+Credentials.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-8.
//

import Foundation
import Combine

// MARK: - Account credentials
extension Mastodon.API.Account {
    
    static func accountsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts")
    }

    /// Register an account
    ///
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
    
}

extension Mastodon.API.Account {
    
    static func verifyCredentialsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/verify_credentials")
    }
    
    /// Verify account credentials
    ///
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
    
    static func updateCredentialsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/update_credentials")
    }
    
    /// Update account credentials
    ///
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
    ///   - authorization: user token
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
    
    public struct UpdateCredentialQuery: PatchQuery {
        public let discoverable: Bool?
        public let bot: Bool?
        public let displayName: String?
        public let note: String?
        public let avatar: Mastodon.Query.MediaAttachment?
        public let header: Mastodon.Query.MediaAttachment?
        public let locked: Bool?
        public let source: Mastodon.Entity.Source?
        public let fieldsAttributes: [Mastodon.Entity.Field]?
        public let indexable: Bool?
        public let hideCollections: Bool?
        
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
            case indexable
            case hideCollections = "hide_collections"
        }

        public init(
            discoverable: Bool? = nil,
            bot: Bool? = nil,
            displayName: String? = nil,
            note: String? = nil,
            avatar: Mastodon.Query.MediaAttachment? = nil,
            header: Mastodon.Query.MediaAttachment? = nil,
            locked: Bool? = nil,
            source: Mastodon.Entity.Source? = nil,
            fieldsAttributes: [Mastodon.Entity.Field]? = nil,
            indexable: Bool? = nil,
            hideCollections: Bool? = nil
        ) {
            self.discoverable = discoverable
            self.bot = bot
            self.displayName = displayName
            self.note = note
            self.avatar = avatar
            self.header = header
            self.locked = locked
            self.source = source
            self.fieldsAttributes = fieldsAttributes
            self.indexable = indexable
            self.hideCollections = hideCollections
        }
        
        var contentType: String? {
            return Self.multipartContentType()
        }
        
        var queryItems: [URLQueryItem]? {
            return nil
        }
        
        var body: Data? {
            var data = Data()

            hideCollections.flatMap { data.append(Data.multipart(key: "hide_collections", value: $0)) }
            discoverable.flatMap { data.append(Data.multipart(key: "discoverable", value: $0)) }
            bot.flatMap { data.append(Data.multipart(key: "bot", value: $0)) }
            displayName.flatMap { data.append(Data.multipart(key: "display_name", value: $0)) }
            note.flatMap { data.append(Data.multipart(key: "note", value: $0)) }
            avatar.flatMap { data.append(Data.multipart(key: "avatar", value: $0)) }
            header.flatMap { data.append(Data.multipart(key: "header", value: $0)) }
            locked.flatMap { data.append(Data.multipart(key: "locked", value: $0)) }
            indexable.flatMap { data.append(Data.multipart(key: "indexable", value: $0)) }
            if let source = source {
                source.privacy.flatMap { data.append(Data.multipart(key: "source[privacy]", value: $0.rawValue)) }
                source.sensitive.flatMap { data.append(Data.multipart(key: "source[privacy]", value: $0)) }
                source.language.flatMap { data.append(Data.multipart(key: "source[privacy]", value: $0)) }
            }
            if let fieldsAttributes = fieldsAttributes {
                if fieldsAttributes.isEmpty {
                    data.append(Data.multipart(key: "fields_attributes[]", value: ""))
                } else {
                    for (i, fieldsAttribute) in fieldsAttributes.enumerated() {
                        data.append(Data.multipart(key: "fields_attributes[\(i)][name]", value: fieldsAttribute.name))
                        data.append(Data.multipart(key: "fields_attributes[\(i)][value]", value: fieldsAttribute.value))
                    }
                }
            }
            
            data.append(Data.multipartEnd())
            return data
        }
    }

}
