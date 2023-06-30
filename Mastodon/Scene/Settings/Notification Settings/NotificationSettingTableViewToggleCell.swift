// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol NotificationSettingToggleCellDelegate: AnyObject {
    
}

class NotificationSettingTableViewToggleCell: ToggleTableViewCell {

    override class var reuseIdentifier: String {
        return "NotificationSettingToggleCell"
    }

    var alert: NotificationAlert?

    weak var delegate: NotificationSettingToggleCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        toggle.addTarget(self, action: #selector(NotificationSettingTableViewToggleCell.toggleValueChanged(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with alert: NotificationAlert, viewModel: NotificationSettingsViewModel) {
        self.alert = alert

        label.text = alert.title
    }

    @objc
    func toggleValueChanged(_ sender: UISwitch) {
        
    }
}
