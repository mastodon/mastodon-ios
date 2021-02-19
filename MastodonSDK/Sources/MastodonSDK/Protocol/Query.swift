//
//  Query.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

enum RequestMethod: String {
    case GET, POST, PATCH, PUT, DELETE
}

protocol RequestQuery {
    // All kinds of queries could have queryItems and body
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

// An `Encodable` query provides its body by encoding itself
// A `Get` query only contains queryItems, it should not be `Encodable`
extension RequestQuery where Self: Encodable {
    var body: Data? {
        return try? Mastodon.API.encoder.encode(self)
    }
}

protocol GetQuery: RequestQuery { }

extension GetQuery {
    // By default a `GetQuery` does not has data body
    var body: Data? { nil }
}

protocol PostQuery: RequestQuery & Encodable { }

extension PostQuery {
    // By default a `GetQuery` does not has query items
    var queryItems: [URLQueryItem]? { nil }
}

protocol PatchQuery: RequestQuery & Encodable { }

extension PatchQuery {
    // By default a `GetQuery` does not has query items
    var queryItems: [URLQueryItem]? { nil }
}
