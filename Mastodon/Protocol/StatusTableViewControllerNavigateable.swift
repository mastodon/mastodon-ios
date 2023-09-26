//
//  StatusTableViewControllerNavigateable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-19.
//

import UIKit
import MastodonAsset
import MastodonLocalization

typealias StatusTableViewControllerNavigateable = StatusTableViewControllerNavigateableCore & StatusTableViewControllerNavigateableRelay

protocol StatusTableViewControllerNavigateableCore: TableViewControllerNavigateableCore {
    var statusNavigationKeyCommands: [UIKeyCommand] { get }
    func statusKeyCommandHandler(_ sender: UIKeyCommand)
}

extension StatusTableViewControllerNavigateableCore {
    var overrideNavigationScrollPosition: UITableView.ScrollPosition? {
        get { return nil }
        set { }
    }
}

@objc protocol StatusTableViewControllerNavigateableRelay: TableViewControllerNavigateableRelay {
    func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand)
}
    
enum StatusTableViewNavigation: String, CaseIterable {
    case openAuthorProfile
    case openRebloggerProfile
    case replyStatus
    case toggleReblog
    case toggleFavorite
    case toggleContentWarning
    case previewImage
    
    var title: String {
        switch self {
        case .openAuthorProfile:    return L10n.Common.Controls.Keyboard.Timeline.openAuthorProfile
        case .openRebloggerProfile: return L10n.Common.Controls.Keyboard.Timeline.openRebloggerProfile
        case .replyStatus:          return L10n.Common.Controls.Keyboard.Timeline.replyStatus
        case .toggleReblog:         return L10n.Common.Controls.Keyboard.Timeline.toggleReblog
        case .toggleFavorite:       return L10n.Common.Controls.Keyboard.Timeline.toggleFavorite
        case .toggleContentWarning: return L10n.Common.Controls.Keyboard.Timeline.toggleContentWarning
        case .previewImage:         return L10n.Common.Controls.Keyboard.Timeline.previewImage
        }
    }
    
    // UIKeyCommand input
    var input: String {
        switch self {
        case .openAuthorProfile:    return "p"
        case .openRebloggerProfile: return "p"  // + option
        case .replyStatus:          return "n"  // + shift + command
        case .toggleReblog:         return "r"
        case .toggleFavorite:       return "f"
        case .toggleContentWarning: return "o"
        case .previewImage:         return "i"
        }
    }
    
    var modifierFlags: UIKeyModifierFlags {
        switch self {
        case .openAuthorProfile:    return []
        case .openRebloggerProfile: return [.alternate]
        case .replyStatus:          return [.shift, .alternate]
        case .toggleReblog:         return []
        case .toggleFavorite:       return []
        case .toggleContentWarning: return []
        case .previewImage:         return []
        }
    }
    
    var propertyList: Any {
        return rawValue
    }
}
