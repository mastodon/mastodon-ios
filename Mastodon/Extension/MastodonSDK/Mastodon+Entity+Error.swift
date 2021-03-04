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
            return "HTTP \(httpResponseStatus.code)"
        }
        switch mastodonError {
        case .generic(let error):
            if let _ = error.details {
                return nil  // Duplicated with the details
            } else {
                return error.error
            }
        }
    }
    
    public var failureReason: String? {
        guard let mastodonError = mastodonError else {
            return httpResponseStatus.reasonPhrase
        }
        switch mastodonError {
        case .generic(let error):
            if let details = error.details {
                return details.failureReason
            } else {
                return error.errorDescription
            }
        }
    }
    
}
