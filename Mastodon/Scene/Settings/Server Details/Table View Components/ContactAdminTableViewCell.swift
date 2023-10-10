// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset
import MastodonLocalization

class ContactAdminTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ContactAdminTableViewCell"

    func configure() {
        var configuration = defaultContentConfiguration()

        configuration.textProperties.color = Asset.Colors.Brand.blurple.color
        configuration.image = UIImage(systemName: "envelope")
        configuration.imageProperties.tintColor = Asset.Colors.Brand.blurple.color
        configuration.text = L10n.Scene.Settings.ServerDetails.AboutInstance.messageAdmin
        backgroundColor = .secondarySystemGroupedBackground

        contentConfiguration = configuration
    }
}
