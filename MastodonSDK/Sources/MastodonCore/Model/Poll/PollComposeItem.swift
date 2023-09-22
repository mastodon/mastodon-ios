//
//  PollComposeItem.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import UIKit
import Combine
import MastodonLocalization
import MastodonAsset

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

        public let backgroundColor = SystemTheme.composePollRowBackgroundColor
        
        public override init() {
            super.init()
        }
    }
}

extension PollComposeItem {
    public final class ExpireConfiguration: Identifiable, Hashable, ObservableObject {
        public let id = UUID()
        
        @Published public var option: Option = .oneDay              // Mastodon
    
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

        public enum Option: String, Hashable, CaseIterable {
            case thirtyMinutes
            case oneHour
            case sixHours
            case oneDay
            case threeDays
            case sevenDays

            public var title: String {
                switch self {
                case .thirtyMinutes: return L10n.Scene.Compose.Poll.thirtyMinutes
                case .oneHour: return L10n.Scene.Compose.Poll.oneHour
                case .sixHours: return L10n.Scene.Compose.Poll.sixHours
                case .oneDay: return L10n.Scene.Compose.Poll.oneDay
                case .threeDays: return L10n.Scene.Compose.Poll.threeDays
                case .sevenDays: return L10n.Scene.Compose.Poll.sevenDays
                }
            }

            public var seconds: Int {
                switch self {
                case .thirtyMinutes: return 60 * 30
                case .oneHour: return 60 * 60 * 1
                case .sixHours: return 60 * 60 * 6
                case .oneDay: return 60 * 60 * 24
                case .threeDays: return 60 * 60 * 24 * 3
                case .sevenDays: return 60 * 60 * 24 * 7
                }
            }
            
            public init(closestDateToExpiry date: Date) {
                let expiresInSeconds = Int(date.timeIntervalSince(.now))
                switch expiresInSeconds {
                case _ where expiresInSeconds <= Self.thirtyMinutes.seconds:
                    self = .thirtyMinutes
                case _ where expiresInSeconds > Self.thirtyMinutes.seconds && expiresInSeconds <= Self.oneHour.seconds:
                    self = .oneHour
                case _ where expiresInSeconds > Self.oneHour.seconds && expiresInSeconds <= Self.sixHours.seconds:
                    self = .sixHours
                case _ where expiresInSeconds > Self.sixHours.seconds && expiresInSeconds <= Self.oneDay.seconds:
                    self = .oneDay
                case _ where expiresInSeconds > Self.oneDay.seconds && expiresInSeconds <= Self.threeDays.seconds:
                    self = .threeDays
                case _ where expiresInSeconds > Self.threeDays.seconds && expiresInSeconds <= Self.sevenDays.seconds:
                    self = .sevenDays
                default:
                    self = .oneDay
                }
            }
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
