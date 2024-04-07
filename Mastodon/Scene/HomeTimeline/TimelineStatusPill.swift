// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class TimelineStatusPill: UIButton {

    var reason: Reason?

    func update(with reason: Reason) {
        self.reason = reason
        var configuration = UIButton.Configuration.filled()

        configuration.attributedTitle = AttributedString(
            reason.title, attributes: AttributeContainer(
                [
                    .font: UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .bold)),
                    .foregroundColor: UIColor.white
                ]
            ))

        let image = reason.image?
            .withConfiguration(UIImage.SymbolConfiguration(paletteColors: [.white]))
            .withConfiguration(UIImage.SymbolConfiguration(textStyle: .subheadline))
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .bold, scale: .medium))

        configuration.image = image
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = reason.backgroundColor
        configuration.cornerStyle = .capsule

        self.configuration = configuration
    }

    public enum Reason {
        case newPosts
        case postSent
        case offline

        var image: UIImage? {
            switch self {
            case .newPosts:
                return UIImage(systemName: "chevron.up")
            case .postSent:
                return UIImage(systemName: "checkmark")
            case .offline:
                return UIImage(systemName: "bolt.horizontal.fill")
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .newPosts:
                return Asset.Colors.Brand.blurple.color
            case .postSent:
                return .systemGreen
            case .offline:
                return .systemGray
            }
        }

        var title: String {
            //TODO: Localization
            switch self {
            case .newPosts:
                return "New Posts"
            case .postSent:
                return "Post Sent"
             case .offline:
                return "Offline"
            }
        }
    }
}
