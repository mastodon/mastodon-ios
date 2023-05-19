// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

public final class FollowButton: RoundedEdgesButton {

    public init() {
        super.init(frame: .zero)
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureAppearance() {
        setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
        setTitleColor(Asset.Colors.Label.primaryReverse.color.withAlphaComponent(0.5), for: .highlighted)
        switch traitCollection.userInterfaceStyle {
        case .dark:
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundDark.color), for: .normal)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedDark.color), for: .highlighted)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedDark.color), for: .disabled)
        default:
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundLight.color), for: .normal)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedLight.color), for: .highlighted)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedLight.color), for: .disabled)
        }
    }
}
