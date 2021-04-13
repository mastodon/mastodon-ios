//
//  Mastodon+API+Statuses.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import Foundation
import Combine

extension Mastodon.API.Statuses {
    
    static func viewStatusEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
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
            url: viewStatusEndpointURL(domain: domain, statusID: statusID),
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
        query: PublishStatusQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.post(
            url: publishNewStatusEndpointURL(domain: domain),
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
    
    public struct PublishStatusQuery: Codable, PostQuery {
        public let status: String?
        public let mediaIDs: [String]?
        public let pollOptions: [String]?
        public let pollExpiresIn: Int?
        public let sensitive: Bool?
        public let spoilerText: String?
        public let visibility: Mastodon.Entity.Status.Visibility?
        
        public init(
            status: String?,
            mediaIDs: [String]?,
            pollOptions: [String]?,
            pollExpiresIn: Int?,
            sensitive: Bool?,
            spoilerText: String?,
            visibility: Mastodon.Entity.Status.Visibility?
        ) {
            self.status = status
            self.mediaIDs = mediaIDs
            self.pollOptions = pollOptions
            self.pollExpiresIn = pollExpiresIn
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.visibility = visibility
            
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
            sensitive.flatMap { data.append(Data.multipart(key: "sensitive", value: $0)) }
            spoilerText.flatMap { data.append(Data.multipart(key: "spoiler_text", value: $0)) }
            visibility.flatMap { data.append(Data.multipart(key: "visibility", value: $0.rawValue)) }

            data.append(Data.multipartEnd())
            return data
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
