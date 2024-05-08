// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

public protocol AccountWarningNotificationCellDelegate: AnyObject {

}

class AccountWarningNotificationCell: UITableViewCell {
    public static let reuseIdentifier = "AccountWarningNotificationCell"

    public func configure(with accountWarning: Mastodon.Entity.AccountWarning) {
        // button, label
        var configuration = defaultContentConfiguration()

        configuration.text = accountWarning.text

        self.contentConfiguration = configuration
    }
}
