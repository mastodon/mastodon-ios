//
//  Mastodon+Entity+Error.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-4.
//

import Foundation
import MastodonSDK

extension Mastodon.API.Error: LocalizedError {
    
    public var errorDescription: String? {
        guard let mastodonError = mastodonError else {
            if let httpResponseStatus {
                return "HTTP \(httpResponseStatus.code)"
            } else {
                return nil
            }
        }
        switch mastodonError {
        case .generic(let error):
            if error.details?.failureReason != nil {
                return nil  // Duplicated with the details
            } else {
                return error.error
            }
        case .decodeError(let message):
            return message
        }
    }
    
    public var failureReason: String? {
        guard let mastodonError = mastodonError else {
            if let httpResponseStatus {
                return httpResponseStatus.reasonPhrase
            } else {
                return nil
            }
        }
        switch mastodonError {
        case .generic(let error):
            if let detailsReason = error.details?.failureReason {
                return detailsReason
            } else {
                return error.errorDescription
            }
        case .decodeError(let message):
            return message
        }
    }
    
}
