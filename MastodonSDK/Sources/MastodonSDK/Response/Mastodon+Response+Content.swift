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
        public let date: Date?
        
        // application fields
        public let rateLimit: RateLimit?
        public let responseTime: Int?
        
        public var networkDate: Date {
            return date ?? Date()
        }
        
        public init(value: T, response: URLResponse) {
            self.value = value
            
            self.date = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "date") else { return nil }
                return Mastodon.API.httpHeaderDateFormatter.date(from: string)
            }()
            
            self.rateLimit = RateLimit(response: response)
            self.responseTime = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "x-response-time") else { return nil }
                return Int(string)
            }()
        }
        
    }
}

extension Mastodon.Response.Content {
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
