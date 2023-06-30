// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

class NotificationSettingTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NotificationSettingTableViewCell"

    func configure(with entry: NotificationSettingEntry, viewModel: NotificationSettingsViewModel) {

        switch entry {
        case.alert(_):
            // we use toggle cells for these
            break
        case .policy:
            var content = UIListContentConfiguration.valueCell()
            //TODO: @zeitschlag Localization
            content.text = "Get Notifications from"
            content.secondaryText = viewModel.selectedPolicy.title

            contentConfiguration = content
        }
    }

}
