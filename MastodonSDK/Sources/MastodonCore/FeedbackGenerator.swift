// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit

public class FeedbackGenerator {

    private let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    
    public enum Impact {
        case light, medium
    }

    public enum Feedback {
        case impact(Impact)
        case notification(UINotificationFeedbackGenerator.FeedbackType)
        case selectionChanged
    }
    
    public static let shared = FeedbackGenerator()
    public var isEnabled = true
    
    public func generate(_ feedback: Feedback) {
        guard isEnabled else { return }
        DispatchQueue.main.async { [self] in
            switch feedback {
            case .impact(.light):
                lightImpactFeedbackGenerator.impactOccurred()
            case .impact(.medium):
                mediumImpactFeedbackGenerator.impactOccurred()
            case let .notification(type):
                notificationFeedbackGenerator.notificationOccurred(type)
            case .selectionChanged:
                selectionFeedbackGenerator.selectionChanged()
            }
        }
    }
}
