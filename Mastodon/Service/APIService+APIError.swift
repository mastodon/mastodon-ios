//
//  APIService+Error.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-2.
//

import UIKit
import MastodonSDK

extension APIService {
    enum APIError: Error {
        
        case implicit(ErrorReason)
        case explicit(ErrorReason)
        
        enum ErrorReason {
            // application internal error
            case authenticationMissing
            case badRequest
            case badResponse
            case requestThrottle
            
            // Server API error
            case mastodonAPIError(Mastodon.API.Error)
        }
        
    }
}
