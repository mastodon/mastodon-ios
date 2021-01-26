//
//  Mastodon+API.swift
//
//
//  Created by xiaojian sun on 2021/1/25.
//

import Foundation
import NIOHTTP1

public extension Mastodon.API {
    static var baseUrl = ""
    static let endpointURL = URL(string: baseUrl + "/api/v1/")!
    
    static let timeoutInterval: TimeInterval = 10
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .MastodonStrategy
        return decoder
    }()

    static let httpHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()
    
    enum App {}
}

extension Mastodon.API {
    // Error Response when request V1 endpoint
    struct ErrorResponse: Codable {
        let errors: [ErrorDescription]
        
        struct ErrorDescription: Codable {
            public let code: Int
            public let message: String
        }
    }
    
    // Alternative Error Response when request V1 endpoint
    struct ErrorRequestResponse: Codable {
        let request: String
        let error: String
    }
}

extension Mastodon.API {

}

private extension JSONDecoder.DateDecodingStrategy {
    static let MastodonStrategy = custom { decoder throws -> Date in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        let formatterV1 = DateFormatter()
        formatterV1.locale = Locale(identifier: "en")
        formatterV1.dateFormat = "EEE MMM dd HH:mm:ss ZZZZZ yyyy"
        if let date = formatterV1.date(from: string) {
            return date
        }
        
        let formatterV2 = ISO8601DateFormatter()
        formatterV2.formatOptions.insert(.withFractionalSeconds)
        if let date = formatterV2.date(from: string) {
            return date
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}
