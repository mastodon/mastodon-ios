//
//  Mastodon+Response+Content.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Response {
    public struct Content<T> {
        
        // entity
        public let value: T
        
        // standard fields
        public let statusCode: Int?        ///< HTTP Code
        public let date: Date?
        
        // application fields
        public let rateLimit: RateLimit?
        public let link: Link?
        public let responseTime: Int?
        
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
             
            self.responseTime = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "x-response-time") else { return nil }
                return Int(string)
            }()
        }
        
        init<O>(value: T, old: Mastodon.Response.Content<O>) {
            self.value = value
            self.statusCode = old.statusCode
            self.date = old.date
            self.rateLimit = old.rateLimit
            self.link = old.link
            self.responseTime = old.responseTime
        }
        
    }
}

extension Mastodon.Response.Content {
    public func map<R>(_ transform: (T) -> R) -> Mastodon.Response.Content<R> {
        return Mastodon.Response.Content(value: transform(value), old: self)
    }
}

extension Mastodon.Response {
    public struct RateLimit {
        
        public let limit: Int
        public let remaining: Int
        public let reset: Date
        
        public init(limit: Int, remaining: Int, reset: Date) {
            self.limit = limit
            self.remaining = remaining
            self.reset = reset
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

extension Mastodon.Response {
    public struct Link {
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
    }
}

public extension Mastodon.Entity.Status.ID {
    static let linkPrev = "prev"
    static let linkNext = "next"
    
    var sinceId: String? {
        components(separatedBy: "&since_id=").last
    }
}
