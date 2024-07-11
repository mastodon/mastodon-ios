//
//  Mastodon+API.swift
//
//
//  Created by xiaojian sun on 2021/1/25.
//

import Foundation
import enum NIOHTTP1.HTTPResponseStatus

extension Mastodon.API {
        
    static let timeoutInterval: TimeInterval = 60
    
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
                if let timestamp = TimeInterval(string) {
                    return Date(timeIntervalSince1970: timestamp)
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
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/oauth/")!
    }
    static func endpointURL(domain: String) -> URL {
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/api/v1/")!
    }
    static func endpointV2URL(domain: String) -> URL {
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/api/v2/")!
    }
    
    static let joinMastodonEndpointURL = URL(string: "https://api.joinmastodon.org/")!
    
    public static func resendEmailURL(domain: String) -> URL {
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/auth/confirmation/new")!
    }
    
    public static func serverRulesURL(domain: String) -> URL {
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/about/more")!
    }
    
    public static func privacyURL(domain: String) -> URL {
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/terms")!
    }

    public static func profileSettingsURL(domain: String) -> URL {
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/auth/edit")!
    }

    public static func webURL(domain: String) -> URL {
        return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/")!
    }
}

extension Mastodon.API {
    public enum V2 { }
    public enum Account { }
    public enum App { }
    public enum Bookmarks { }
    public enum CustomEmojis { }
    public enum Favorites { }
    public enum Instance { }
    public enum Media { }
    public enum OAuth { }
    public enum Onboarding { }
    public enum Polls { }
    public enum Reblog { }
    public enum Statuses { }
    public enum Tags {}
    public enum Timeline { }
    public enum Trends { }
    public enum Suggestions { }
    public enum Notifications { }
    public enum Subscriptions { }
    public enum Reports { }
    public enum DomainBlock { }
    public enum Lists { }
}

extension Mastodon.API.V2 {
    public enum Search { }
    public enum Suggestions { }
    public enum Media { }
    public enum Instance { }
}

extension Mastodon.API {
    
    static func get(
        url: URL,
        query: GetQuery? = nil,
        authorization: OAuth.Authorization? = nil
    ) -> URLRequest {
        return buildRequest(url: url, method: .GET, query: query, authorization: authorization)
    }
    
    static func post(
        url: URL,
        query: PostQuery?,
        authorization: OAuth.Authorization? = nil
    ) -> URLRequest {
        return buildRequest(url: url, method: .POST, query: query, authorization: authorization)
    }

    static func patch(
        url: URL,
        query: PatchQuery?,
        authorization: OAuth.Authorization? = nil
    ) -> URLRequest {
        return buildRequest(url: url, method: .PATCH, query: query, authorization: authorization)
    }
    
    static func put(
        url: URL,
        query: PutQuery? = nil,
        authorization: OAuth.Authorization? = nil
    ) -> URLRequest {
        return buildRequest(url: url, method: .PUT, query: query, authorization: authorization)
    }
    
    static func delete(
        url: URL,
        query: DeleteQuery?,
        authorization: OAuth.Authorization? = nil
    ) -> URLRequest {
        return buildRequest(url: url, method: .DELETE, query: query, authorization: authorization)
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
        if let contentType = query?.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let body = query?.body {
            request.httpBody = body
            request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }
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
            debugPrint("URL: \(String(describing: response.url))\nData: \(String(data: data, encoding: .utf8) ?? "-")\nError:\(decodeError)\n----\n")
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
