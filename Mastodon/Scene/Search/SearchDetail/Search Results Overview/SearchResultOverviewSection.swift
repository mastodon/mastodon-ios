// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import CoreDataStack

enum SearchResultOverviewSection: Hashable {
    case `default`
    case suggestions
}

enum SearchResultOverviewItem: Hashable {
    case `default`(DefaultSectionEntry)
    case suggestion(SuggestionSectionEntry)
    
    enum DefaultSectionEntry: Hashable {
        case posts(String)
        case people(String)
        case profile(String, String)
        case openLink(String)

        var title: String {
            switch self {
                    //TODO: Add localization
                case .posts(let text):
                    return "Posts with \(text)"
                case .people(let username):
                    return "People with \(username)"
                case .profile(let username, let instanceName):
                    return "Go to @\(username)@\(instanceName)"
                case .openLink(_):
                    return "Open Link"
            }
        }

        var icon: UIImage? {
            switch self {
                case .posts(_):
                    return UIImage(systemName: "number")
                case .people(_):
                    return UIImage(systemName: "person.2")
                case .profile(_, _):
                    return UIImage(systemName: "person.crop.circle")
                case .openLink(_):
                    return UIImage(systemName: "link")
            }
        }
    }
    
    enum SuggestionSectionEntry: Hashable {
        case hashtag(tag: Mastodon.Entity.Tag)
        case profile(user: Mastodon.Entity.Account)
        
        var title: String? {
            if case let .hashtag(tag) = self {
                return tag.name
            } else {
                return nil
            }
        }
        
        var icon: UIImage? {
            if case .hashtag(_) = self {
                return UIImage(systemName: "number")
            } else {
                return nil
            }
        }
    }
}
