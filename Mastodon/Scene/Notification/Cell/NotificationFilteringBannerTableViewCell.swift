// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

class NotificationFilteringBannerTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NotificationFilteringBannerTableViewCell"

    //TODO: Add separator

    func configure(with policy: Mastodon.Entity.NotificationPolicy) {
        var configuration = defaultContentConfiguration()

        //TODO: Add localization
        configuration.text = "Filtered notifications"
        configuration.secondaryText = "\(policy.summary.pendingRequestsCount) people you may know"
        configuration.image = UIImage(systemName: "archivebox")

        self.contentConfiguration = configuration

    }
}
