// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class NotificationSettingsDisabledTableViewCell: UITableViewCell {

    static let reuseIdentifier = "NotificationSettingsDisabledTableViewCell"

    let appBadgeImageView: UIImageView
    let notificationHintLabel: UILabel
    let goToSettingsLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        appBadgeImageView = UIImageView(image: UIImage(systemName: "app.badge.fill"))
        appBadgeImageView.tintColor = Asset.Colors.Brand.blurple.color
        appBadgeImageView.translatesAutoresizingMaskIntoConstraints = false

        notificationHintLabel = UILabel()
        notificationHintLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationHintLabel.numberOfLines = 0
        notificationHintLabel.textColor = .label
        notificationHintLabel.text = "Turn on notifications from your device settings to see updates on your lock screen."
        notificationHintLabel.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16, weight: .regular))

        goToSettingsLabel = UILabel()
        goToSettingsLabel.textColor = Asset.Colors.Brand.blurple.color
        goToSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
        goToSettingsLabel.text = "Go to Notification Settings"
        goToSettingsLabel.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16, weight: .bold))

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(appBadgeImageView)
        contentView.addSubview(notificationHintLabel)
        contentView.addSubview(goToSettingsLabel)

        backgroundColor = Asset.Colors.Brand.blurple.color.withAlphaComponent(0.15)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints: [NSLayoutConstraint] = [
            appBadgeImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            appBadgeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            appBadgeImageView.widthAnchor.constraint(equalToConstant: 34),
            appBadgeImageView.heightAnchor.constraint(equalToConstant: 34),

            notificationHintLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            notificationHintLabel.leadingAnchor.constraint(equalTo: appBadgeImageView.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: notificationHintLabel.trailingAnchor, constant: 16),

            goToSettingsLabel.topAnchor.constraint(equalTo: notificationHintLabel.bottomAnchor, constant: 8),
            goToSettingsLabel.leadingAnchor.constraint(equalTo: notificationHintLabel.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: goToSettingsLabel.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: goToSettingsLabel.bottomAnchor, constant: 16),
        ]

        NSLayoutConstraint.activate(constraints)
    }
}

