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
    
    static let httpHeaderDateFormatter: ISO8601DateFormatter = {
        var formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter
    }()
    static let fractionalSecondsPreciseISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter
    }()
    static let fullDatePreciseISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter
    }()
    
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom { decoder throws -> Date in
            let container = try decoder.singleValueContainer()
            
            var logInfo = ""
            do {
                let string = try container.decode(String.self)
                logInfo += string
                
                if let date = fractionalSecondsPreciseISO8601Formatter.date(from: string) {
                    return date
                }
                if let date = fullDatePreciseISO8601Formatter.date(from: string) {
                    return date
                }
            } catch {
                // do nothing
            }
            
            var numberValue = ""
            do {
                let number = try container.decode(Double.self)
                logInfo += "\(number)"
                
                return Date(timeIntervalSince1970: number)
            } catch {
                // do nothing
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "[Decoder] Invalid date: \(logInfo)")
        }
        
        return decoder
    }()
    
    static func oauthEndpointURL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/oauth/")!
    }
    static func endpointURL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/api/v1/")!
    }
    static func endpointV2URL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/api/v2/")!
    }
    
    static let joinMastodonEndpointURL = URL(string: "https://api.joinmastodon.org/")!
    
    public static func resendEmailURL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/auth/confirmation/new")!
    }
    
}

extension Mastodon.API {
    public enum Account { }
    public enum App { }
    public enum Instance { }
    public enum OAuth { }
    public enum Onboarding { }
    public enum Timeline { }
    public enum Favorites { }
}

extension Mastodon.API {
    
    static func get(
        url: URL,
        query: GetQuery?,
        authorization: OAuth.Authorization?
    ) -> URLRequest {
        return buildRequest(url: url, method: .GET, query: query, authorization: authorization)
    }
    
    static func post(
        url: URL,
        query: PostQuery?,
        authorization: OAuth.Authorization?
    ) -> URLRequest {
        return buildRequest(url: url, method: .POST, query: query, authorization: authorization)
    }

    static func patch(
        url: URL,
        query: PatchQuery?,
        authorization: OAuth.Authorization?
    ) -> URLRequest {
        return buildRequest(url: url, method: .PATCH, query: query, authorization: authorization)
    }

    private static func buildRequest(
        url: URL,
        method: RequestMethod,
        query: RequestQuery?,
        authorization: OAuth.Authorization?
    ) -> URLRequest {
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = query?.queryItems
        let requestURL = components.url!
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Mastodon.API.timeoutInterval
        )
        request.httpMethod = method.rawValue
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = query?.body
        if let authorization = authorization {
            request.setValue(
                "Bearer \(authorization.accessToken)",
                forHTTPHeaderField: Mastodon.API.OAuth.authorizationField
            )
        }
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
            if let error = try? Mastodon.API.decoder.decode(Mastodon.Entity.Error.self, from: data) {
                throw Mastodon.API.Error(httpResponseStatus: httpResponseStatus, error: error)
            }
            
            throw Mastodon.API.Error(httpResponseStatus: httpResponseStatus, mastodonError: nil)
        }
    }
    
}
