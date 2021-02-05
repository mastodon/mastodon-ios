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
        
        private var errorReason: ErrorReason {
            switch self {
            case .implicit(let errorReason):        return errorReason
            case .explicit(let errorReason):        return errorReason
            }
        }
        
    }
}

// MARK: - LocalizedError
extension APIService.APIError: LocalizedError {
    
    var errorDescription: String? {
        switch errorReason {
        case .authenticationMissing:        return "Fail to Authenticatie"
        case .badRequest:                   return "Bad Request"
        case .badResponse:                  return "Bad Response"
        case .requestThrottle:              return "Request Throttled"
        case .mastodonAPIError(let error):
            guard let responseError = error.mastodonError else {
                guard error.httpResponseStatus != .ok else {
                    return "Unknown Error"
                }
                return error.httpResponseStatus.reasonPhrase
            }
            
            return responseError.errorDescription
        }
    }
    
    var failureReason: String? {
        switch errorReason {
        case .authenticationMissing:        return "Account credential not found."
        case .badRequest:                   return "Request invalid."
        case .badResponse:                  return "Response invalid."
        case .requestThrottle:              return "Request too frequency."
        case .mastodonAPIError(let error):
            guard let responseError = error.mastodonError else {
                return nil
            }
            return responseError.failureReason
        }
    }
    
    var helpAnchor: String? {
        switch errorReason {
        case .authenticationMissing:        return "Please request after authenticated."
        case .badRequest:                   return "Please try again."
        case .badResponse:                  return "Please try again."
        case .requestThrottle:              return "Please try again later."
        case .mastodonAPIError(let error):
            guard let responseError = error.mastodonError else {
                return nil
            }
            return responseError.helpAnchor
        }
    }
    
}
