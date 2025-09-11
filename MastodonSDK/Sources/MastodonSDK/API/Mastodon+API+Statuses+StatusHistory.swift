// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Combine

extension Mastodon.API.Statuses {
    private static func historyEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("statuses")
            .appendingPathComponent(statusID)
            .appendingPathComponent("history")
    }

    private static func statusSourceEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("statuses")
            .appendingPathComponent(statusID)
            .appendingPathComponent("source")
    }

    public static func statusSource(
        forStatusID statusID: Mastodon.Entity.Status.ID,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.StatusSource>, Error> {
        let url = statusSourceEndpointURL(domain: domain, statusID: statusID)
        let request = Mastodon.API.get(url: url, authorization: authorization)

        return session.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.StatusSource.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()

    }


    /// Get all known versions of a status, including the initial and current states.
    ///
    /// - Since: 3.5.0
    ///
    /// # Last Update
    ///
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/#history)
    ///
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `StatusEdit` nested in the response
    public static func editHistory(
        forStatusID statusID: Mastodon.Entity.Status.ID,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.StatusEdit]>, Error> {

        let url = historyEndpointURL(domain: domain, statusID: statusID)
        let request = Mastodon.API.get(url: url, authorization: authorization)

        return session.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.StatusEdit].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    /// Edit a given status to change its text, sensitivity, media attachments, or poll. Note that editing a poll’s options will reset the votes.
    ///
    /// - Since: 3.5.0
    /// - Version: 4.0.0
    /// # Last Update
    ///   2021/3/18
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/#edit)
    ///
    /// - Parameters:
    ///   - statusID: ID of the status that is to be edited
    ///   - editStatusQuery: Basically the edits (Status, Emoji, Media...), is a `EditStatusQuery`
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` that contains the updated `Status` nested in the response
    public static func editStatus(
        forStatusID statusID: Mastodon.Entity.Status.ID,
        editStatusQuery: EditStatusQuery,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let url = statusEndpointURL(domain: domain, statusID: statusID)
        let request = Mastodon.API.put(url: url, query: editStatusQuery, authorization: authorization)

        return session.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                let editedStatus = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: editedStatus, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Mastodon.API.Statuses {

    public struct MediaAttributes: Codable {
        let id: String
        let description: String?
        //TODO: Add focus at some point

        public init(id: String, description: String?) {
            self.id = id
            self.description = description
        }
    }

    public struct Poll: Codable {
        public let options: [String]?
        public let expiresIn: Int?
        public let multipleAnswers: Bool?

        public init(options: [String]?, expiresIn: Int?, multipleAnswers: Bool?) {
            self.options = options
            self.expiresIn = expiresIn
            self.multipleAnswers = multipleAnswers
        }

        enum CodingKeys: String, CodingKey {
            case options
            case expiresIn = "expires_in"
            case multipleAnswers = "multiple_answers"
        }
    }

    public struct EditStatusQuery: Codable, PutQuery {
        public let status: String?
        public let mediaIDs: [String]?
        public let mediaAttributes: [MediaAttributes]?
        public let poll: Poll?
        public let sensitive: Bool?
        public let spoilerText: String?
        public let visibility: Mastodon.Entity.Status.Visibility?
        public let quotability: Mastodon.Entity.Source.QuotePolicy?
        public let language: String?

        public init(
            status: String?,
            mediaIDs: [String]?,
            mediaAttributes: [MediaAttributes]? = nil,
            poll: Poll?,
            sensitive: Bool?,
            spoilerText: String?,
            visibility: Mastodon.Entity.Status.Visibility?,
            quotability: Mastodon.Entity.Source.QuotePolicy?,
            language: String?
        ) {
            self.status = status
            self.mediaIDs = mediaIDs
            self.mediaAttributes = mediaAttributes
            self.poll = poll
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.visibility = visibility
            self.quotability = quotability
            self.language = language
        }

        enum CodingKeys: String, CodingKey {
            case status
            case mediaIDs = "media_ids"
            case mediaAttributes = "media_attributes"
            case poll
            case sensitive
            case spoilerText = "spoiler_text"
            case visibility
            case quotability = "quote_approval_policy"
            case language
        }
    }
}
