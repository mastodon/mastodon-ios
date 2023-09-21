//
//  TableViewControllerNavigateable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-21.
//

import UIKit
import MastodonAsset
import MastodonLocalization

typealias TableViewControllerNavigateable = TableViewControllerNavigateableCore & TableViewControllerNavigateableRelay

protocol TableViewControllerNavigateableCore: AnyObject {
    var tableView: UITableView { get }
    var overrideNavigationScrollPosition: UITableView.ScrollPosition? { get set }
    var navigationKeyCommands: [UIKeyCommand] { get }
    
    func navigateKeyCommandHandler(_ sender: UIKeyCommand)
    func navigate(direction: TableViewNavigationDirection)
    func open()
    func back()
}

extension TableViewControllerNavigateableCore {
    var overrideNavigationScrollPosition: UITableView.ScrollPosition? {
        get { return nil }
        set { }
    }
}

@objc protocol TableViewControllerNavigateableRelay: AnyObject {
    func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand)
}

enum TableViewNavigationDirection {
    case up
    case down
}

enum TableViewNavigation: String, CaseIterable {
    case up
    case down
    case back                   // pop
    case open
    
    var title: String {
        switch self {
        case .up:                   return L10n.Common.Controls.Actions.previous
        case .down:                 return L10n.Common.Controls.Actions.next
        case .back:                 return L10n.Common.Controls.Actions.back
        case .open:                 return L10n.Common.Controls.Actions.open
        }
    }
    
    // UIKeyCommand input
    var input: String {
        switch self {
        case .up:                   return "k"
        case .down:                 return "j"
        case .back:                 return "h"
        case .open:                 return "l"  // little "L"
        }
    }
    
    var modifierFlags: UIKeyModifierFlags {
        switch self {
        case .up:                   return []
        case .down:                 return []
        case .back:                 return []
        case .open:                 return []
        }
    }
    
    var propertyList: Any {
        return rawValue
    }
}


