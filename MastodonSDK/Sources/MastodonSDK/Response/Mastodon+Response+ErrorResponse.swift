//
//  Mastodon+Response+ErrorResponse.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Response {
    public struct ErrorResponse: Codable {
        public let error: String
        public let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "error_description"
        }
    }
}
