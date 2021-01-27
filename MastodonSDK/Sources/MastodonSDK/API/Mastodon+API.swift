//
//  Mastodon+API.swift
//
//
//  Created by xiaojian sun on 2021/1/25.
//

import Foundation
import NIOHTTP1

public extension Mastodon.API {
    
    static func endpointURL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/api/v1/")!
    }
    
    static let timeoutInterval: TimeInterval = 10
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return decoder
    }()

    static let httpHeaderDateFormatter = ISO8601DateFormatter()
    
    enum Error { }
    enum App { }
    
}
