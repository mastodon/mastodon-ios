// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class ContactAdminTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ContactAdminTableViewCell"

    func configure() {
        var configuration = defaultContentConfiguration()

        configuration.textProperties.color = Asset.Colors.Brand.blurple.color
        configuration.image = UIImage(systemName: "envelope")
        configuration.imageProperties.tintColor = Asset.Colors.Brand.blurple.color
        configuration.text = "Contact Admin"

        contentConfiguration = configuration
    }
}
