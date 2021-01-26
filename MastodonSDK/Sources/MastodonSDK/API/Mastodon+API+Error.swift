//
//  Mastodon+API+Error.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/26.
//

import Foundation

extension Mastodon.API.Error {
    
    struct ErrorResponse: Codable {
        let error: String
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "error_description"
        }
    }
    
}
