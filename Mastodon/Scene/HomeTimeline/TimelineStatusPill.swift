// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset
import MastodonLocalization

class TimelineStatusPill: UIButton {

    var reason: Reason?

    func update(with reason: Reason) {
        self.reason = reason
        var configuration = UIButton.Configuration.filled()

        configuration.attributedTitle = AttributedString(
            reason.title, attributes: AttributeContainer(
                [
                    .font: UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .bold)),
                ]
            ))

        let image = reason.image?
            .withConfiguration(UIImage.SymbolConfiguration(paletteColors: [.white]))
            .withConfiguration(UIImage.SymbolConfiguration(textStyle: .subheadline))
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .bold, scale: .medium))

        configuration.image = image
        configuration.imagePadding = 8
        configuration.cornerStyle = .capsule
        configuration.background.backgroundColor = reason.backgroundColor

        self.configuration = configuration

        layer.shadowColor = reason.backgroundColor.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = .init(width: 0, height: 8)
        layer.shadowRadius = 8
    }

    override func updateConfiguration() {
        guard let reason, var updatedConfiguration = configuration else {
            return super.updateConfiguration()
        }

        switch state {
        case .selected, .highlighted, .focused:
            updatedConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.5)
        default:
            updatedConfiguration.baseForegroundColor = .white
        }

        updatedConfiguration.background.backgroundColor = reason.backgroundColor
        self.configuration = updatedConfiguration
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
            switch self {
            case .newPosts:
                return L10n.Scene.HomeTimeline.TimelinePill.newPosts
            case .postSent:
                return L10n.Scene.HomeTimeline.TimelinePill.postSent
             case .offline:
                return L10n.Scene.HomeTimeline.TimelinePill.offline
            }
        }
    }
}
