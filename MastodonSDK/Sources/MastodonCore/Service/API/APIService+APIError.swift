//
//  APIService+Error.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-2.
//

import UIKit
import MastodonSDK
import MastodonLocalization

extension APIService {
    public enum APIError: Error {
        
        case implicit(ErrorReason)
        case explicit(ErrorReason)
        
        public enum ErrorReason {
            // application internal error
            case authenticationMissing
            case badRequest
            case badResponse
            case requestThrottle
            
            case voteExpiredPoll
            
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
    
    public var errorDescription: String? {
        switch errorReason {
        case .authenticationMissing:        return "Fail to Authenticate"
        case .badRequest:                   return "Bad Request"
        case .badResponse:                  return "Bad Response"
        case .requestThrottle:              return "Request Throttled"
        case .voteExpiredPoll:              return L10n.Common.Alerts.VoteFailure.title
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
    
    public var failureReason: String? {
        switch errorReason {
        case .authenticationMissing:        return "Account credential not found."
        case .badRequest:                   return "Request invalid."
        case .badResponse:                  return "Response invalid."
        case .requestThrottle:              return "Request too frequency."
        case .voteExpiredPoll:              return L10n.Common.Alerts.VoteFailure.pollEnded
        case .mastodonAPIError(let error):
            guard let responseError = error.mastodonError else {
                return nil
            }
            return responseError.failureReason
        }
    }
    
    public var helpAnchor: String? {
        switch errorReason {
        case .authenticationMissing:        return "Please request after authenticated."
        case .badRequest:                   return L10n.Common.Alerts.Common.pleaseTryAgain
        case .badResponse:                  return L10n.Common.Alerts.Common.pleaseTryAgain
        case .requestThrottle:              return L10n.Common.Alerts.Common.pleaseTryAgainLater
        case .voteExpiredPoll:              return nil
        case .mastodonAPIError(let error):
            guard let responseError = error.mastodonError else {
                return nil
            }
            return responseError.helpAnchor
        }
    }
    
}
