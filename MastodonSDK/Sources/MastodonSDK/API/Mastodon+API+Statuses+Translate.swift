//
//  Mastodon+API+Statuses+Translate.swift
//
//
//  Created by Marcus Kida on 02.12.2022.
//

import Foundation
import Combine

extension Mastodon.API.Statuses {
    
    private static func translateEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("statuses")
            .appendingPathComponent(statusID)
            .appendingPathComponent("translate")
    }

    public struct TranslateQuery: Codable, PostQuery {
        public let lang: String
    }

    /// Translate Status
    ///
    /// Translate a given Status.
    ///
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func translate(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorization: Mastodon.API.OAuth.Authorization?,
        targetLanguage: String?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Translation>, Error> {

        let query: TranslateQuery?

        if let targetLanguage {
            query = TranslateQuery(lang: targetLanguage)
        } else {
            query = nil
        }

        let request = Mastodon.API.post(
            url: translateEndpointURL(domain: domain, statusID: statusID),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Translation.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
