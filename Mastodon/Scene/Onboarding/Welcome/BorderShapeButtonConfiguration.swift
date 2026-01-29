// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import UIKit

extension UIButton.Configuration {
    @discardableResult
    mutating func welcomeBorderedShapeConfiguration() -> UIButton.Configuration {
        background.cornerRadius = 14
        background.strokeColor = UIColor.white.withAlphaComponent(0.6)
        background.strokeWidth = 1
        baseBackgroundColor = .clear
        baseForegroundColor = .white
        return self
    }

    @discardableResult
    mutating func defaultWelcome() -> UIButton.Configuration {
        let plainConfig = UIButton.Configuration.plain()
        background = plainConfig.background
        baseBackgroundColor = plainConfig.baseForegroundColor
        baseForegroundColor = .white
        return self
    }
}
