// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class AboutMastodonTableViewCell: UITableViewCell {
    static let reuseIdentifier = "AboutMastodonTableViewCell"

    func configure(with entry: AboutSettingsEntry) {
        var contentConfiguration = UIListContentConfiguration.valueCell()

        contentConfiguration.text = entry.text
        contentConfiguration.secondaryText = entry.secondaryText
        contentConfiguration.textProperties.color = Asset.Colors.Brand.blurple.color

        self.contentConfiguration = contentConfiguration
    }
}
