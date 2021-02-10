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
    var body: Data? { get }
    var method: RequestMethod { get }
}

extension RequestQuery where method: Encodable {
    var body: Data? {
        return try? Mastodon.API.encoder.encode(self)
    }
}

protocol GetQuery: RequestQuery {
    var queryItems: [URLQueryItem]? { get }
}

extension GetQuery {
    var method: RequestMethod { return .GET }
    var body: Data? { return nil }
}

protocol PostQuery: RequestQuery { }

extension PostQuery {
    var method: RequestMethod { return .POST }
}

protocol PatchQuery: RequestQuery { }

extension PatchQuery {
    var method: RequestMethod { return .PATCH }
}
