//
//  Mastodon+Response+Content.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Response {
    public struct Content<T: Sendable>: Sendable {
        
        // entity
        public let value: T
        
        // standard fields
        public let statusCode: Int?        ///< HTTP Code
        public let date: Date?
        
        // application fields
        public let rateLimit: RateLimit?
        public let link: Link?
        public let asyncRefreshAvaliable: AsyncRefreshAvailable?
        public let responseTime: Int?
        public let deprecation: Date?
        
        public var networkDate: Date {
            return date ?? Date()
        }
        
        public init(value: T, response: URLResponse) {
            self.value = value
            
            self.statusCode = (response as? HTTPURLResponse)?.statusCode
            
            self.date = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "date") else { return nil }
                return Mastodon.API.httpHeaderDateFormatter.date(from: string)
            }()
            
            self.rateLimit = RateLimit(response: response)
            self.link = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "link") else { return nil }
                return Link(link: string)
            }()
            
            self.asyncRefreshAvaliable = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "mastodon-async-refresh") else { return nil }
                return AsyncRefreshAvailable(asyncRefreshHeader: string)
            }()
             
            self.responseTime = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "x-response-time") else { return nil }
                return Int(string)
            }()

            self.deprecation = deprecationDate(response)
        }
        
        init<O>(value: T, old: Mastodon.Response.Content<O>) {
            self.value = value
            self.statusCode = old.statusCode
            self.date = old.date
            self.rateLimit = old.rateLimit
            self.link = old.link
            self.asyncRefreshAvaliable = old.asyncRefreshAvaliable
            self.responseTime = old.responseTime
            self.deprecation = old.deprecation
        }
        
    }
}

extension Mastodon.Response.Content {
    public func map<R>(_ transform: (T) -> R) -> Mastodon.Response.Content<R> {
        return Mastodon.Response.Content(value: transform(value), old: self)
    }
}

extension Mastodon.Response {
    public struct RateLimit: Sendable {
        
        public let limit: Int
        public let remaining: Int
        public let reset: Date
        
        public init(limit: Int, remaining: Int, reset: Date) {
            self.limit = limit
            self.remaining = remaining
            self.reset = reset
#if DEBUG && false
            print("LIMIT: \(limit), REMAINING: \(remaining), RESET: \(reset), NOW: \(Date.now)")
#endif
            RateLimitViewModel.shared.didReceiveRateLimit(self)
        }
        
        public init?(response: URLResponse) {
            guard let response = response as? HTTPURLResponse else {
                return nil
            }
            
            guard let limitString = response.value(forHTTPHeaderField: "X-RateLimit-Limit"),
                  let limit = Int(limitString),
                  let remainingString = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
                  let remaining = Int(remainingString) else {
                return nil
            }
            
            guard let resetTimestampString = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
                  let reset = Mastodon.API.httpHeaderDateFormatter.date(from: resetTimestampString) else {
                return nil
            }
            
            self.init(limit: limit, remaining: remaining, reset: reset)
        }
        
    }
}

fileprivate func deprecationDate(_ response: URLResponse) -> Date? {
    /// The `Deprecation` HTTP response header field https://datatracker.ietf.org/doc/html/rfc9745
    guard let response = response as? HTTPURLResponse else { return nil }
    guard let deprecationValue = response.value(forHTTPHeaderField: "Deprecation") else { return nil }
    let date: Date? = { // date is a time interval since 1970, with a preceding '@'
        let trimmed = deprecationValue.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("@"), let timestamp = TimeInterval(trimmed.dropFirst()) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }()
    
    if let date {
        DispatchQueue.main.async {
            DeprecationTracker.shared.didReceiveDeprecation(date, endpoint: response.url?.path() ?? "unknown")
        }
    }
    return date
}

extension Mastodon.Response {
    public struct Link: Sendable {
        public let maxID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let linkIDs: [String: Mastodon.Entity.Status.ID]
        public let offset: Int?
        
        init(link: String) {
            self.maxID = {
                guard let regex = try? NSRegularExpression(pattern: "max_id=([[:digit:]]+)", options: []) else { return nil }
                let results = regex.matches(in: link, options: [], range: NSRange(link.startIndex..<link.endIndex, in: link))
                guard let match = results.first else { return nil }
                guard let range = Range(match.range(at: 1), in: link) else { return nil }
                let id = link[range]
                return String(id)
            }()
            
            self.minID = {
                guard let regex = try? NSRegularExpression(pattern: "min_id=([[:digit:]]+)", options: []) else { return nil }
                let results = regex.matches(in: link, options: [], range: NSRange(link.startIndex..<link.endIndex, in: link))
                guard let match = results.first else { return nil }
                guard let range = Range(match.range(at: 1), in: link) else { return nil }
                let id = link[range]
                return String(id)
            }()
            
            self.offset = {
                guard let regex = try? NSRegularExpression(pattern: "offset=([[:digit:]]+)", options: []) else { return nil }
                let results = regex.matches(in: link, options: [], range: NSRange(link.startIndex..<link.endIndex, in: link))
                guard let match = results.first else { return nil }
                guard let range = Range(match.range(at: 1), in: link) else { return nil }
                let offset = link[range]
                return Int(offset)
            }()
            self.linkIDs = {
                var linkIDs = [String: Mastodon.Entity.Status.ID]()
                let links = link.components(separatedBy: ", ")
                for link in links {
                    guard let regex = try? NSRegularExpression(pattern: "<(.*)>; *rel=\"(.*)\"") else { return [:] }
                    let results = regex.matches(in: link, options: [], range: NSRange(link.startIndex..<link.endIndex, in: link))
                    for match in results {
                        guard
                            let labelRange = Range(match.range(at: 2), in: link),
                            let linkRange = Range(match.range(at: 1), in: link)
                        else {
                            continue
                        }
                        linkIDs[String(link[labelRange])] = String(link[linkRange])
                    }
                }
                return linkIDs
            }()
        }
        
        public var nextUrl: URL? {
            guard let string = linkIDs["next"] else { return nil }
            return URL(string: string)
        }
        
        public var prevUrl: URL? {
            guard let string = linkIDs["prev"] else { return nil }
            return URL(string: string)
        }
    }
}

public extension Mastodon.Entity.Status.ID {
    static let linkPrev = "prev"
    static let linkNext = "next"
    
    var sinceId: String? {
        components(separatedBy: "&since_id=").last
    }
}

extension Mastodon.Response {
    public struct AsyncRefreshAvailable: Sendable {
        public let id: String
        public let retryInterval: Int   // number of seconds to wait before requerying either the original endpoint or the async refresh update endpoint
        public let resultCount: Int?    // number of results already fetched
        
        init?(asyncRefreshHeader: String) {
            let _retryInterval: Int? = {
                guard let regex = try? NSRegularExpression(pattern: "retry=([[:digit:]]+)", options: []) else { return nil }
                let results = regex.matches(in: asyncRefreshHeader, options: [], range: NSRange(asyncRefreshHeader.startIndex..<asyncRefreshHeader.endIndex, in: asyncRefreshHeader))
                guard let match = results.first else { return nil }
                guard let range = Range(match.range(at: 1), in: asyncRefreshHeader) else { return nil }
                let retry = asyncRefreshHeader[range]
                return Int(retry)
            }()
            
            guard let retryInterval = _retryInterval else { return nil }
            self.retryInterval = retryInterval
            
            let _resultCount: Int? = {
                guard let regex = try? NSRegularExpression(pattern: "result_count=([[:digit:]]+)", options: []) else { return nil }
                let results = regex.matches(in: asyncRefreshHeader, options: [], range: NSRange(asyncRefreshHeader.startIndex..<asyncRefreshHeader.endIndex, in: asyncRefreshHeader))
                guard let match = results.first else { return nil }
                guard let range = Range(match.range(at: 1), in: asyncRefreshHeader) else { return nil }
                let count = asyncRefreshHeader[range]
                return Int(count)
            }()
            
            guard let resultCount = _resultCount else { return nil }
            self.resultCount = resultCount
            
            let _id: String? = {
                guard let regex = try? NSRegularExpression(pattern: "id=\"([^\"]+)", options: []) else { return nil }
                let results = regex.matches(in: asyncRefreshHeader, options: [], range: NSRange(asyncRefreshHeader.startIndex..<asyncRefreshHeader.endIndex, in: asyncRefreshHeader))
                guard let match = results.first else { return nil }
                guard let range = Range(match.range(at: 1), in: asyncRefreshHeader) else { return nil }
                let id = asyncRefreshHeader[range]
                return String(id)
            }()
            
            guard let id = _id else { return nil }
            self.id = id
        }
    }
}
