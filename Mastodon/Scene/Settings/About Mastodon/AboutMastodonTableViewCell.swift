// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class AboutMastodonTableViewCell: UITableViewCell {
    static let reuseIdentifier = "AboutMastodonTableViewCell"

    func configure(with entry: AboutSettingsEntry) {
        switch entry.type {
        case .navigation:
            var contentConfiguration = UIListContentConfiguration.cell()

            contentConfiguration.text = entry.text
            contentConfiguration.secondaryText = entry.secondaryText
            contentConfiguration.textProperties.color = .label

            accessoryType = .disclosureIndicator

            self.contentConfiguration = contentConfiguration

        case .action:
            var contentConfiguration = UIListContentConfiguration.valueCell()

            contentConfiguration.text = entry.text
            contentConfiguration.secondaryText = entry.secondaryText
            contentConfiguration.textProperties.color = Asset.Colors.Brand.blurple.color

            accessoryType = .none

            self.contentConfiguration = contentConfiguration
        }
    }
}
