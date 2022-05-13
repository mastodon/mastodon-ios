//
//  PageboyNavigateable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-11.
//

import UIKit
import Pageboy
import MastodonLocalization

typealias PageboyNavigateable = PageboyNavigateableCore & PageboyNavigateableRelay

protocol PageboyNavigateableCore: AnyObject {
    var navigateablePageViewController: PageboyViewController { get }
    var pageboyNavigateKeyCommands: [UIKeyCommand] { get }

    func pageboyNavigateKeyCommandHandler(_ sender: UIKeyCommand)
    func navigate(direction: PageboyNavigationDirection)
}

@objc protocol PageboyNavigateableRelay: AnyObject {
    func pageboyNavigateKeyCommandHandlerRelay(_ sender: UIKeyCommand)
}

enum PageboyNavigationDirection: String, CaseIterable {
    case previous
    case next

    var title: String {
        switch self {
        case .previous:             return L10n.Common.Controls.Keyboard.SegmentedControl.previousSection
        case .next:                 return L10n.Common.Controls.Keyboard.SegmentedControl.nextSection
        }
    }
    
    // UIKeyCommand input
    var input: String {
        switch self {
        case .previous:             return "["
        case .next:                 return "]"
        }
    }
    
    var modifierFlags: UIKeyModifierFlags {
        switch self {
        case .previous:             return [.shift, .command]
        case .next:                 return [.shift, .command]
        }
    }
    
    var propertyList: Any {
        return rawValue
    }
}

extension PageboyNavigateableCore where Self: PageboyNavigateableRelay {
    var pageboyNavigateKeyCommands: [UIKeyCommand] {
        PageboyNavigationDirection.allCases.map { direction in
            UIKeyCommand(
                title: direction.title,
                image: nil,
                action: #selector(Self.pageboyNavigateKeyCommandHandlerRelay(_:)),
                input: direction.input,
                modifierFlags: direction.modifierFlags,
                propertyList: direction.propertyList,
                alternates: [],
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            )
        }
    }
    
    func pageboyNavigateKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let direction = PageboyNavigationDirection(rawValue: rawValue) else { return }
        navigate(direction: direction)
    }

}

extension PageboyNavigateableCore {
    func navigate(direction: PageboyNavigationDirection) {
        switch direction {
        case .previous:
            navigateablePageViewController.scrollToPage(.previous, animated: true)
        case .next:
            navigateablePageViewController.scrollToPage(.next, animated: true)
        }
    }
}
