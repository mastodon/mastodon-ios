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
    case homeTimeline(UserIdentifier)
    case notificationsMentions(UserIdentifier)
    case notificationsAll(UserIdentifier)
    
    private func uniqueUserDomainIdentifier(for userIdentifier: UserIdentifier) -> String {
        "\(userIdentifier.userID)@\(userIdentifier.domain)"
    }

    private var filename: String {
        switch self {
            case .searchHistory:
                return "search_history" // todo: @zeitschlag should this be user-scoped as well?
            case let .homeTimeline(userIdentifier):
            return "home_timeline_\(uniqueUserDomainIdentifier(for: userIdentifier))"
            case let .notificationsMentions(userIdentifier):
                return "notifications_mentions_\(uniqueUserDomainIdentifier(for: userIdentifier))"
            case let .notificationsAll(userIdentifier):
                return "notifications_all_\(uniqueUserDomainIdentifier(for: userIdentifier))"
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

