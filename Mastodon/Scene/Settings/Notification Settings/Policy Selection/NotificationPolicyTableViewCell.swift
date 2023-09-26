// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class NotificationPolicyTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NotificationPolicyTableViewCell"

    func configure(with policy: NotificationPolicy, selectedPolicy: NotificationPolicy) {
        var content = UIListContentConfiguration.cell()
        content.text = policy.title
        tintColor = Asset.Colors.Brand.blurple.color

        if policy == selectedPolicy {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }

        contentConfiguration = content
    }
}
