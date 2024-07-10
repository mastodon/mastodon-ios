// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit

protocol NotificationPolicyFilterTableViewCellDelegate: AnyObject {
    func toggleValueChanged(_ tableViewCell: NotificationPolicyFilterTableViewCell, filterItem: NotificationFilterItem, newValue: Bool)
}

class NotificationPolicyFilterTableViewCell: ToggleTableViewCell {
    override class var reuseIdentifier: String {
        return "NotificationPolicyFilterTableViewCell"
    }

    var filterItem: NotificationFilterItem?
    weak var delegate: NotificationPolicyFilterTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))

        toggle.addTarget(self, action: #selector(NotificationPolicyFilterTableViewCell.toggleValueChanged(_:)), for: .valueChanged)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func configure(with filterItem: NotificationFilterItem, viewModel: NotificationFilterViewModel) {
        label.text = filterItem.title
        subtitleLabel.text = filterItem.subtitle
        self.filterItem = filterItem

        let toggleIsOn: Bool
        switch filterItem {
        case .notFollowing:
            toggleIsOn = viewModel.notFollowing
        case .noFollower:
            toggleIsOn = viewModel.noFollower
        case .newAccount:
            toggleIsOn = viewModel.newAccount
        case .privateMentions:
            toggleIsOn = viewModel.privateMentions
        }

        toggle.isOn = toggleIsOn
    }

    @objc func toggleValueChanged(_ sender: UISwitch) {
        guard let filterItem, let delegate else { return }

        delegate.toggleValueChanged(self, filterItem: filterItem, newValue: sender.isOn)
    }
}
