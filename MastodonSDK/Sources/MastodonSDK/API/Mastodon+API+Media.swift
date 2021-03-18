//
//  Mastodon+API+Media.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import Foundation
import Combine

extension Mastodon.API.Media {
    
    static func uploadMediaEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("media")
    }
    
    /// Upload media as attachment
    ///
    /// Creates an attachment to be used with a new status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/18
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/media/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `UploadMediaQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Attachment` nested in the response
    public static func uploadMedia(
        session: URLSession,
        domain: String,
        query: UploadMeidaQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error>  {
        var request = Mastodon.API.post(
            url: uploadMediaEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        request.timeoutInterval = 180    // should > 200 Kb/s for 40 MiB media attachment
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Attachment.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct UploadMeidaQuery: PostQuery {
        public let file: Mastodon.Query.MediaAttachment?
        public let thumbnail: Mastodon.Query.MediaAttachment?
        public let description: String?
        public let focus: String?
        
        public init(
            file: Mastodon.Query.MediaAttachment?,
            thumbnail: Mastodon.Query.MediaAttachment?,
            description: String?,
            focus: String?
        ) {
            self.file = file
            self.thumbnail = thumbnail
            self.description = description
            self.focus = focus
        }
        
        var contentType: String? {
            return Self.multipartContentType()
        }
        
        var body: Data? {
            var data = Data()

            file.flatMap { data.append(Data.multipart(key: "file", value: $0)) }
            thumbnail.flatMap { data.append(Data.multipart(key: "thumbnail", value: $0)) }
            description.flatMap { data.append(Data.multipart(key: "description", value: $0)) }
            focus.flatMap { data.append(Data.multipart(key: "focus", value: $0)) }
            
            data.append(Data.multipartEnd())
            return data
        }
    }
    
}
