//
//  Mastodon+API+Error+MastodonAPIError.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.API.Error {
    public enum MastodonAPIError: Swift.Error {
        case generic(errorResponse: Mastodon.Response.ErrorResponse)
        
        init(errorResponse: Mastodon.Response.ErrorResponse) {
            self = .generic(errorResponse: errorResponse)
        }
    }
}
