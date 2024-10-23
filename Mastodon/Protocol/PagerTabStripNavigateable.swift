//
//  PagerTabStripNavigateable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-6-2.
//

import UIKit
import XLPagerTabStrip
import MastodonLocalization

typealias PagerTabStripNavigateable = PagerTabStripNavigateableCore & PagerTabStripNavigateableRelay

protocol PagerTabStripNavigateableCore: AnyObject {
    var navigateablePageViewController: PagerTabStripViewController? { get }
    var pagerTabStripNavigateKeyCommands: [UIKeyCommand] { get }

    func pagerTabStripNavigateKeyCommandHandler(_ sender: UIKeyCommand)
    func navigate(direction: PagerTabStripNavigationDirection)
}

@objc protocol PagerTabStripNavigateableRelay: AnyObject {
    func pagerTabStripNavigateKeyCommandHandlerRelay(_ sender: UIKeyCommand)
}

enum PagerTabStripNavigationDirection: String, CaseIterable {
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

extension PagerTabStripNavigateableCore where Self: PagerTabStripNavigateableRelay {
    var pagerTabStripNavigateKeyCommands: [UIKeyCommand] {
        PagerTabStripNavigationDirection.allCases.map { direction in
            UIKeyCommand(
                title: direction.title,
                image: nil,
                action: #selector(Self.pagerTabStripNavigateKeyCommandHandlerRelay(_:)),
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
    
    func pagerTabStripNavigateKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let direction = PagerTabStripNavigationDirection(rawValue: rawValue) else { return }
        navigate(direction: direction)
    }

}

extension PagerTabStripNavigateableCore {
    func navigate(direction: PagerTabStripNavigationDirection) {
        guard let navigateablePageViewController = navigateablePageViewController else { return }
        let index = navigateablePageViewController.currentIndex
        let targetIndex: Int
        
        switch direction {
        case .previous:
            targetIndex = index - 1
        case .next:
            targetIndex = index + 1
        }
        
        guard targetIndex >= 0,
              !navigateablePageViewController.viewControllers.isEmpty,
              targetIndex < navigateablePageViewController.viewControllers.count,
              navigateablePageViewController.canMoveTo(index: targetIndex)
        else {
            return
        }
        
        navigateablePageViewController.moveToViewController(at: targetIndex)
    }
}

