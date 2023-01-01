//
//  PollComposeItem.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import UIKit
import Combine
import MastodonLocalization
import CoreDataStack

public enum PollComposeItem: Hashable {
    case option(Option)
    case expireConfiguration(ExpireConfiguration)
    case multipleConfiguration(MultipleConfiguration)
}

extension PollComposeItem {
    public final class Option: NSObject, Identifiable, ObservableObject {
        public let id = UUID()

        public weak var textField: UITextField?
        
        // input
        @Published public var text = ""
        @Published public var shouldBecomeFirstResponder = false
        
        // output
        @Published public var backgroundColor = ThemeService.shared.currentTheme.value.composePollRowBackgroundColor
        
        public override init() {
            super.init()
            
            ThemeService.shared.currentTheme
                .map { $0.composePollRowBackgroundColor }
                .assign(to: &$backgroundColor)
        }
    }
}

extension PollComposeItem {
    public final class ExpireConfiguration: Identifiable, Hashable, ObservableObject {
        public let id = UUID()
        
        @Published public var option: Draft.Poll.Expiration = .oneDay              // Mastodon
    
        public init() {
            // end init
        }
        
        public static func == (lhs: ExpireConfiguration, rhs: ExpireConfiguration) -> Bool {
            return lhs.id == rhs.id
                && lhs.option == rhs.option
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension PollComposeItem {
    public final class MultipleConfiguration: Hashable, ObservableObject {
        private let id = UUID()
        
        @Published public var isMultiple: Option = false
        
        public init() {
            // end init
        }
        
        public typealias Option = Bool
        
        public static func == (lhs: MultipleConfiguration, rhs: MultipleConfiguration) -> Bool {
            return lhs.id == rhs.id
                && lhs.isMultiple == rhs.isMultiple
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
