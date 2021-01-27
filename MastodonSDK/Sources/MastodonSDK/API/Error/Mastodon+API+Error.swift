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
        public var mastodonAPIError: MastodonAPIError?
        
        init(
            httpResponseStatus: HTTPResponseStatus,
            mastodonAPIError: Mastodon.API.Error.MastodonAPIError?
        ) {
            self.httpResponseStatus = httpResponseStatus
            self.mastodonAPIError = mastodonAPIError
        }
        
        init(
            httpResponseStatus: HTTPResponseStatus,
            errorResponse: Mastodon.Response.ErrorResponse
        ) {
            self.init(
                httpResponseStatus: httpResponseStatus,
                mastodonAPIError: MastodonAPIError(errorResponse: errorResponse)
            )
        }
        
    }
}
