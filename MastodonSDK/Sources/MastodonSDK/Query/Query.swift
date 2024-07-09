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
    var contentType: String? { get }
    var body: Data? { get }
}

extension RequestQuery {
    static func multipartContentType(boundary: String = Multipart.boundary) -> String {
        return "multipart/form-data; charset=utf-8; boundary=\"\(boundary)\""
    }
}

// An `Encodable` query provides its body by encoding itself
// A `Get` query only contains queryItems, it should not be `Encodable`
extension RequestQuery where Self: Encodable {
    var contentType: String? {
        return "application/json"
    }
    var body: Data? {
        return try? Mastodon.API.encoder.encode(self)
    }
}

// GET
protocol GetQuery: RequestQuery { }

extension GetQuery {
    // By default a `GetQuery` does not has data body
    var body: Data? { nil }
    var contentType: String? { nil }
}

// POST
protocol PostQuery: RequestQuery { }

extension PostQuery {
    // By default a `PostQuery` does not have query items
    var queryItems: [URLQueryItem]? { nil }
}

// PATCH
protocol PatchQuery: RequestQuery { }

extension PatchQuery {
    // By default a `PostQuery` does not have query items
    var queryItems: [URLQueryItem]? { nil }
}

// PUT
protocol PutQuery: RequestQuery { }

extension PutQuery {
    // By default a `PutQuery` does not have query items
    var queryItems: [URLQueryItem]? { nil }
}

// DELETE
protocol DeleteQuery: RequestQuery { }

extension DeleteQuery {
    // By default a `DeleteQuery` does not have query items
    var queryItems: [URLQueryItem]? { nil }
}
