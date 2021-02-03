//
//  Mastodon+API+Error+MastodonAPIError.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.API.Error {
    public enum MastodonError: Swift.Error {
        case generic(error: Mastodon.Entity.Error)
        
        init(error: Mastodon.Entity.Error) {
            self = .generic(error: error)
        }
    }
}

// MARK: - LocalizedError
extension Mastodon.API.Error.MastodonError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .generic(let error):
            return error.error
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .generic(let error):
            return error.errorDescription
        }
    }
    
}
