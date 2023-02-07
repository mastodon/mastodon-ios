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
    public struct EditStatusQuery: Codable, PutQuery {
        var queryItems: [URLQueryItem]? = nil

        public let status: String?
        public let mediaIDs: [String]?
        public let pollOptions: [String]?
        public let pollExpiresIn: Int?
        public let pollMultipleAnswers: Bool?
        public let sensitive: Bool?
        public let spoilerText: String?
        public let visibility: Mastodon.Entity.Status.Visibility?
        public let language: String?

        public init(
            status: String?,
            mediaIDs: [String]?,
            pollOptions: [String]?,
            pollExpiresIn: Int?,
            pollMultipleAnswers: Bool?,
            sensitive: Bool?,
            spoilerText: String?,
            visibility: Mastodon.Entity.Status.Visibility?,
            language: String?
        ) {
            self.status = status
            self.mediaIDs = mediaIDs
            self.pollOptions = pollOptions
            self.pollExpiresIn = pollExpiresIn
            self.pollMultipleAnswers = pollMultipleAnswers
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.visibility = visibility
            self.language = language
        }

        enum CodingKeys: String, CodingKey {
            case status
            case mediaIDs
            case pollOptions
            case pollExpiresIn
            case pollMultipleAnswers
            case sensitive
            case spoilerText
            case visibility
            case language
        }
    }
}
