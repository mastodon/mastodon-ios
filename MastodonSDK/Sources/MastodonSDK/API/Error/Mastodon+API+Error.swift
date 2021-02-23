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

extension Mastodon.API.Error: LocalizedError {
    
    public var errorDescription: String? {
        guard let mastodonError = mastodonError else {
            return nil
        }
        switch mastodonError {
        case .generic(let error):
            return error.error
        }
    }
    
    public var failureReason: String? {
        guard let mastodonError = mastodonError else {
            return nil
        }
        switch mastodonError {
        case .generic(let error):
            return error.errorDescription
        }
    }
    
}
