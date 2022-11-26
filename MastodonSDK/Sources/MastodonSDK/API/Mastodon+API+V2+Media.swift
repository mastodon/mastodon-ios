//
//  Mastodon+API+V2+Media.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import Foundation
import Combine

extension Mastodon.API.V2.Media {
    static func uploadMediaEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("media")
    }

    /// Upload media as attachment
    ///
    /// Creates an attachment to be used with a new status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.1
    /// # Last Update
    ///   2021/7/15
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
        query: Mastodon.API.Media.UploadMediaQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error>  {
        var request = Mastodon.API.post(
            url: uploadMediaEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        request.timeoutInterval = 180    // should > 200 Kb/s for 40 MiB media attachment
        let serialStream = query.serialStream
        request.httpBodyStream = serialStream.boundStreams.input
        
        // total unit count in bytes count
        // will small than actally count due to multipart protocol meta
        serialStream.progress.totalUnitCount = {
            var size = 0
            size += query.file?.sizeInByte ?? 0
            size += query.thumbnail?.sizeInByte ?? 0
            return Int64(size)
        }()
        query.progress.addChild(
            serialStream.progress,
            withPendingUnitCount: query.progress.totalUnitCount
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Attachment.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .handleEvents(receiveCancel: {
                // retain and handle cancel task
                serialStream.boundStreams.output.close()
            })
            .eraseToAnyPublisher()
    }
}
