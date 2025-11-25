//
//  Mastodon+Entity+AsyncRefresh.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/21/25.
//

extension Mastodon.Entity {
    
    public struct AsyncRefreshResult: Codable {
        public let result: AsyncRefresh?
        public let errorString: String?
        
        enum CodingKeys: String, CodingKey {
            case result = "async_refresh"
            case errorString = "error"
        }
    }
    
    /// AsyncRefresh
    ///
    /// - Since: 4.4.0  (beta feature)
    /// - Version: 4.4.0
    /// # Last Update
    ///   2025/11/24
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/AsyncRefresh/)
    public struct AsyncRefresh: Codable {
        public let id: String
        public let status: Status
        public let resultCount: Int?
        
        public enum Status: RawRepresentable, Codable, Hashable, Sendable {
            case running
            case finished

            case _other(String)
            
            public init?(rawValue: String) {
                switch rawValue {
                case "running":         self = .running
                case "finished":        self = .finished
                default:                self = ._other(rawValue)
                }
            }
            
            public var rawValue: String {
                switch self {
                case .running:              return "running"
                case .finished:             return "finished"
                case ._other(let value):    return value
                }
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id
            case status
            case resultCount = "result_count"
        }
    }
}
