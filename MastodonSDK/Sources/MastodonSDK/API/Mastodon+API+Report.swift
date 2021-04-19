//
//  File.swift
//  
//
//  Created by ihugo on 2021/4/19.
//

import Combine
import Foundation

extension Mastodon.API.Reports {
    static func reportsEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("reports")
    }

    /// File a report
    ///
    /// Version history:
    /// 1.1 - added
    /// 2.3.0 - add forward parameter
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/search/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: fileReportQuery query
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains status indicate if report sucessfully.
    public static func fileReport(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Reports.FileReportQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Bool>, Error> {
        let request = Mastodon.API.post(
            url: reportsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let response = response as? HTTPURLResponse {
                    return Mastodon.Response.Content(
                        value: response.statusCode == 200,
                        response: response
                    )
                }
                return Mastodon.Response.Content(value: false, response: response)
            }
            .eraseToAnyPublisher()
    }
}


public extension Mastodon.API.Reports {
    class FileReportQuery: Codable, PostQuery {
        public let accountId: String
        public var statusIds: [String]?
        public var comment: String?
        public let forward: Bool?
        
        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case statusIds = "status_ids"
            case comment
            case forward
        }
        
        public init(accountId: String,
             statusIds: [String]?,
             comment: String?,
             forward: Bool?) {
            self.accountId = accountId
            self.statusIds = statusIds
            self.comment = comment
            self.forward = forward
        }
    }
}
