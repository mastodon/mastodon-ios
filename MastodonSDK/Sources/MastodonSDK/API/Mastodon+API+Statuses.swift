//
//  Mastodon+API+Statuses.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import Foundation
import Combine

extension Mastodon.API.Statuses {
    
    static func statusEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        let pathComponent = "statuses/" + statusID
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// View specific status
    ///
    /// View information about a status
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/10
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func status(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Poll.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.get(
            url: statusEndpointURL(domain: domain, statusID: statusID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Statuses {

    static func publishNewStatusEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("statuses")
    }
    
    /// Publish new status
    ///
    /// Post a new status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/18
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `PublishStatusQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func publishStatus(
        session: URLSession,
        domain: String,
        idempotencyKey: String?,
        query: PublishStatusQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        var request = Mastodon.API.post(
            url: publishNewStatusEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        if let idempotencyKey = idempotencyKey {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct PublishStatusQuery: Codable, PostQuery {
        public let status: String?
        public let mediaIDs: [String]?
        public let pollOptions: [String]?
        public let pollExpiresIn: Int?
        public let inReplyToID: Mastodon.Entity.Status.ID?
        public let quotingID: Mastodon.Entity.Status.ID?
        public let sensitive: Bool?
        public let spoilerText: String?
        public let visibility: Mastodon.Entity.Status.Visibility?
        public let quotePolicy: Mastodon.Entity.Source.QuotePolicy?
        public let language: String?
        
        public init(
            status: String?,
            mediaIDs: [String]?,
            pollOptions: [String]?,
            pollExpiresIn: Int?,
            inReplyToID: Mastodon.Entity.Status.ID?,
            quotingID: Mastodon.Entity.Status.ID?,
            sensitive: Bool?,
            spoilerText: String?,
            visibility: Mastodon.Entity.Status.Visibility?,
            quotePolicy: Mastodon.Entity.Source.QuotePolicy?,
            language: String?
        ) {
            self.status = status
            self.mediaIDs = mediaIDs
            self.pollOptions = pollOptions
            self.pollExpiresIn = pollExpiresIn
            self.inReplyToID = inReplyToID
            self.quotingID = quotingID
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.visibility = visibility
            self.quotePolicy = quotePolicy
            self.language = language
        }
        
        var contentType: String? {
            return Self.multipartContentType()
        }
        
        var body: Data? {
            var data = Data()

            status.flatMap { data.append(Data.multipart(key: "status", value: $0)) }
            for mediaID in mediaIDs ?? [] {
                data.append(Data.multipart(key: "media_ids[]", value: mediaID))
            }
            for pollOption in pollOptions ?? [] {
                data.append(Data.multipart(key: "poll[options][]", value: pollOption))
            }
            pollExpiresIn.flatMap { data.append(Data.multipart(key: "poll[expires_in]", value: $0)) }
            inReplyToID.flatMap { data.append(Data.multipart(key: "in_reply_to_id", value: $0)) }
            quotingID.flatMap { data.append(Data.multipart(key: "quoted_status_id", value: $0)) }
            sensitive.flatMap { data.append(Data.multipart(key: "sensitive", value: $0)) }
            spoilerText.flatMap { data.append(Data.multipart(key: "spoiler_text", value: $0)) }
            visibility.flatMap { data.append(Data.multipart(key: "visibility", value: $0.rawValue)) }
            quotePolicy.flatMap { data.append(Data.multipart(key: "quote_approval_policy", value: $0.rawValue)) }
            language.flatMap { data.append(Data.multipart(key: "language", value: $0)) }
            
            data.append(Data.multipartEnd())
            return data
        }

    }
    
}

extension Mastodon.API.Statuses {
    
    /// Delete status
    ///
    /// Delete one of your own statuses.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/5/7
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `DeleteStatusQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func deleteStatus(
        session: URLSession,
        domain: String,
        query: DeleteStatusQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.delete(
            url: statusEndpointURL(domain: domain, statusID: query.id),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct DeleteStatusQuery: Codable, DeleteQuery {
        public let id: Mastodon.Entity.Status.ID
        
        public init(
            id: Mastodon.Entity.Status.ID
        ) {
            self.id = id
        }
    }
    
    /// Revoke quote authorization
    ///
    /// Revoke a single post's authorization to quote one of your own statuses.
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///   2025/9/11
    /// # Reference
    ///   [Document](not yet published)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `RevokeQuoteAuthorizationQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func revokeQuoteAuthorization(
        session: URLSession,
        domain: String,
        query: RevokeQuoteAuthorizationQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        var url = statusEndpointURL(domain: domain, statusID: query.quotedId)
        for component in ["quotes", query.quotingId, "revoke"] {
            url.append(path: component)
        }
        let request = Mastodon.API.revokeQuoteAuthorization(
            url: url,
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct RevokeQuoteAuthorizationQuery: Codable, PostQuery {
        public let quotedId: Mastodon.Entity.Status.ID
        public let quotingId: Mastodon.Entity.Status.ID
        
        public init(
            quotedId: Mastodon.Entity.Status.ID,
            quotingId: Mastodon.Entity.Status.ID
        ) {
            self.quotedId = quotedId
            self.quotingId = quotingId
        }
        
        var body: Data? {
            return nil  // all of the information is included in the url
        }
    }
    
    /// Update quote policy
    ///
    /// Change a single post's quote policy going forward.
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///   2025/9/12
    /// # Reference
    ///   [Document](not yet published)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `UpdateQuotePolicyQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func updateQuotePolicy(
        session: URLSession,
        domain: String,
        query: UpdateQuotePolicyQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        var url = statusEndpointURL(domain: domain, statusID: query.statusId)
        for component in ["interaction_policy"] {
            url.append(path: component)
        }
        let request = Mastodon.API.updateQuotePolicy(
            url: url,
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct UpdateQuotePolicyQuery: Codable, PutQuery {
        public let statusId: Mastodon.Entity.Status.ID
        public let newPolicy: Mastodon.Entity.Source.QuotePolicy
        
        public init(
            statusId: Mastodon.Entity.Status.ID,
            newPolicy: Mastodon.Entity.Source.QuotePolicy
        ) {
            self.statusId = statusId
            self.newPolicy = newPolicy
        }
        
        var body: Data? {
            // the affected statusID is in the url, we only need to send the new policy here
            // sending as JSON rather than form encoding because attempting with form encoding returned http status 400
            do {
                let dict = [ "quote_approval_policy" : newPolicy.rawValue ]
                return try JSONSerialization.data(withJSONObject: dict)
            } catch {
                assertionFailure("Error creating quote policy update query body: \(error)")
                return nil
            }
        }
    }
}

extension Mastodon.API.Statuses {

    static func statusContextEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("statuses/\(statusID)/context")
    }
    
    /// Parent and child statuses
    ///
    /// View statuses above and below this status in the thread.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/12
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id of status
    ///   - authorization: User token. Optional for public statuses
    /// - Returns: `AnyPublisher` contains `Context` nested in the response
    public static func statusContext(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Context>, Error>  {
        let request = Mastodon.API.get(
            url: statusContextEndpointURL(domain: domain, statusID: statusID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Context.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
