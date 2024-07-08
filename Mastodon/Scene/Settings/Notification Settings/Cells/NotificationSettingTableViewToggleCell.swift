// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol NotificationSettingToggleCellDelegate: AnyObject {
    func toggleValueChanged(_ tableViewCell: NotificationSettingTableViewToggleCell, alert: NotificationAlert, newValue: Bool)
}

class NotificationSettingTableViewToggleCell: ToggleTableViewCell {

    override class var reuseIdentifier: String {
        return "NotificationSettingToggleCell"
    }

    var alert: NotificationAlert?

    weak var delegate: NotificationSettingToggleCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        subtitleLabel.isHidden = true

        toggle.addTarget(self, action: #selector(NotificationSettingTableViewToggleCell.toggleValueChanged(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with alert: NotificationAlert, viewModel: NotificationSettingsViewModel, notificationsEnabled: Bool) {

        isUserInteractionEnabled = notificationsEnabled
        self.alert = alert
        
        let toggleIsOn: Bool
        switch alert {
            case .mentionsAndReplies:
                toggleIsOn = viewModel.notifyMentions
            case .boosts:
                toggleIsOn = viewModel.notifyBoosts
            case .favorites:
                toggleIsOn = viewModel.notifyFavorites
            case .newFollowers:
                toggleIsOn = viewModel.notifyNewFollowers
        }

        label.text = alert.title
        if notificationsEnabled {
            label.textColor = .label
        } else {
            label.textColor = .secondaryLabel
        }
        toggle.isOn = toggleIsOn && notificationsEnabled
        toggle.isEnabled = notificationsEnabled
    }

    @objc
    func toggleValueChanged(_ sender: UISwitch) {
        guard let alert else { return }

        delegate?.toggleValueChanged(self, alert: alert, newValue: sender.isOn)
    }
}
