//
//  Mastodon+API+Error.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/26.
//

import Foundation
import enum NIOHTTP1.HTTPResponseStatus

extension Mastodon.API {
    public struct Error: Swift.Error {
        
        public var httpResponseStatus: HTTPResponseStatus
        public var mastodonError: MastodonError?
        
        init(
            httpResponseStatus: HTTPResponseStatus,
            mastodonError: Mastodon.API.Error.MastodonError?
        ) {
            self.httpResponseStatus = httpResponseStatus
            self.mastodonError = mastodonError
        }
        
        init(
            httpResponseStatus: HTTPResponseStatus,
            error: Mastodon.Entity.Error
        ) {
            self.init(
                httpResponseStatus: httpResponseStatus,
                mastodonError: MastodonError(error: error)
            )
        }
        
    }
}
