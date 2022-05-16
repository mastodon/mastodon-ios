//
//  File.swift
//  
//
//  Created by ihugo on 2021/4/19.
//

import Combine
import Foundation
import enum NIOHTTP1.HTTPResponseStatus

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
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/reports/)
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
                guard let response = response as? HTTPURLResponse else {
                    assertionFailure()
                    throw NSError()
                }
                
                if response.statusCode == 200 {
                    return Mastodon.Response.Content(
                        value: true,
                        response: response
                    )
                } else {
                    let httpResponseStatus = HTTPResponseStatus(statusCode: response.statusCode)
                    throw Mastodon.API.Error(
                        httpResponseStatus: httpResponseStatus,
                        mastodonError: nil
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}


public extension Mastodon.API.Reports {
    class FileReportQuery: Codable, PostQuery {
        public let accountID: Mastodon.Entity.Account.ID
        public var statusIDs: [Mastodon.Entity.Status.ID]?
        public var comment: String?
        public let forward: Bool?
         
        public let category: Category?
        public let ruleIDs: [Mastodon.Entity.Instance.Rule.ID]?
        
        enum CodingKeys: String, CodingKey {
            case accountID = "account_id"
            case statusIDs = "status_ids"
            case comment
            case forward
            case category
            case ruleIDs = "rule_ids"
            
        }
        
        public enum Category: String, Codable {
            case spam
            case violation
            case other
        }
        
        public init(
            accountID: Mastodon.Entity.Account.ID,
            statusIDs: [Mastodon.Entity.Status.ID]?,
            comment: String?,
            forward: Bool?,
            category: Category?,
            ruleIDs: [Mastodon.Entity.Instance.Rule.ID]?
        ) {
            self.accountID = accountID
            self.statusIDs = statusIDs
            self.comment = comment
            self.forward = forward
            self.category = category
            self.ruleIDs = ruleIDs
        }
    }
}
