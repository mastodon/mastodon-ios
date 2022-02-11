//
//  SegmentedControlNavigateable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-21.
//

import UIKit
import MastodonAsset
import MastodonLocalization

typealias SegmentedControlNavigateable = SegmentedControlNavigateableCore & SegmentedControlNavigateableRelay

protocol SegmentedControlNavigateableCore: AnyObject {
    var navigateableSegmentedControl: UISegmentedControl { get }
    var segmentedControlNavigateKeyCommands: [UIKeyCommand] { get }
    
    func segmentedControlNavigateKeyCommandHandler(_ sender: UIKeyCommand)
    func navigate(direction: SegmentedControlNavigationDirection)
}

@objc protocol SegmentedControlNavigateableRelay: AnyObject {
    func segmentedControlNavigateKeyCommandHandlerRelay(_ sender: UIKeyCommand)
}

enum SegmentedControlNavigationDirection: String, CaseIterable {
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

extension SegmentedControlNavigateableCore where Self: SegmentedControlNavigateableRelay {
    var segmentedControlNavigateKeyCommands: [UIKeyCommand] {
        SegmentedControlNavigationDirection.allCases.map { direction in
            UIKeyCommand(
                title: direction.title,
                image: nil,
                action: #selector(Self.segmentedControlNavigateKeyCommandHandlerRelay(_:)),
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
    
    func segmentedControlNavigateKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let direction = SegmentedControlNavigationDirection(rawValue: rawValue) else { return }
        navigate(direction: direction)
    }

}

extension SegmentedControlNavigateableCore {
    func navigate(direction: SegmentedControlNavigationDirection) {
        let index: Int = {
            let selectedIndex = navigateableSegmentedControl.selectedSegmentIndex
            switch direction {
            case .previous:     return selectedIndex - 1
            case .next:         return selectedIndex + 1
            }
        }()
        
        guard 0..<navigateableSegmentedControl.numberOfSegments ~= index else { return }
        navigateableSegmentedControl.selectedSegmentIndex = index
        navigateableSegmentedControl.sendActions(for: .valueChanged)
    }
}
