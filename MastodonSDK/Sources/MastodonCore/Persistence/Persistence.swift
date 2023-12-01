//
//  Persistence.swift
//  Persistence
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

public enum Persistence {
    case searchHistory
    case homeTimeline(String)

    private var filename: String {
        switch self {
            case .searchHistory:
                return "search_history"
            case let .homeTimeline(userId):
                return "home_timeline_\(userId)"
        }
    }

    public func filepath(baseURL: URL) -> URL {
        baseURL
            .appending(path: filename)
            .appendingPathExtension("json")
    }
}


extension Persistence {
    public enum MastodonUser { }
    public enum Status { }
    public enum Poll { }
    public enum Card { }
    public enum PollOption { }
    public enum Tag { }
    public enum SearchHistory { }
    public enum Notification { }
}

extension Persistence {
    public class PersistCache<T> {
        var dictionary: [String : T] = [:]
        
        public init(dictionary: [String : T] = [:]) {
            self.dictionary = dictionary
        }
    }
}

