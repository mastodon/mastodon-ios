// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

public final class FollowButton: UIButton {

    public init() {
        super.init(frame: .zero)
        configureAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureAppearance() {
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.background.cornerRadius = 10
        self.configuration = buttonConfiguration
    }
}
