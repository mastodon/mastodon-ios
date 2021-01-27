//
//  Mastodon+API.swift
//
//
//  Created by xiaojian sun on 2021/1/25.
//

import Foundation
import enum NIOHTTP1.HTTPResponseStatus

extension Mastodon.API {
        
    static let timeoutInterval: TimeInterval = 10
    static let httpHeaderDateFormatter = ISO8601DateFormatter()
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return decoder
    }()
    
    static func endpointURL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/api/v1/")!
    }
    
}

extension Mastodon.API {
    public enum App { }
    public enum OAuth { }
    public enum Timeline { }
}

extension Mastodon.API {
    
    static func request(
        url: URL,
        query: GetQuery,
        authorization: OAuth.Authorization?
    ) -> URLRequest {
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = query.queryItems
        
        let requestURL = components.url!
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Mastodon.API.timeoutInterval
        )
        if let authorization = authorization {
            request.setValue(
                "Bearer \(authorization.accessToken)",
                forHTTPHeaderField: Mastodon.API.OAuth.authorizationField
            )
        }
        request.httpMethod = "GET"
        return request
    }
    
    static func request(
        url: URL,
        query: PostQuery,
        authorization: OAuth.Authorization?
    ) -> URLRequest {
        let components = URLComponents(string: url.absoluteString)!
        let requestURL = components.url!
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Mastodon.API.timeoutInterval
        )
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = query.body
        if let authorization = authorization {
            request.setValue(
                "Bearer \(authorization.accessToken)",
                forHTTPHeaderField: Mastodon.API.OAuth.authorizationField
            )
        }
        request.httpMethod = "POST"
        return request
    }
    
    static func decode<T>(type: T.Type, from data: Data, response: URLResponse) throws -> T where T : Decodable {
        // decode data then decode error if could
        do {
            return try Mastodon.API.decoder.decode(type, from: data)
        } catch let decodeError {
            #if DEBUG
            debugPrint(decodeError)
            #endif
            
            guard let httpURLResponse = response as? HTTPURLResponse else {
                assertionFailure()
                throw decodeError
            }
            
            let httpResponseStatus = HTTPResponseStatus(statusCode: httpURLResponse.statusCode)
            if let errorResponse = try? Mastodon.API.decoder.decode(Mastodon.Response.ErrorResponse.self, from: data) {
                throw Mastodon.API.Error(httpResponseStatus: httpResponseStatus, errorResponse: errorResponse)
            }
            
            throw Mastodon.API.Error(httpResponseStatus: httpResponseStatus, mastodonAPIError: nil)
        }
    }
    
}
