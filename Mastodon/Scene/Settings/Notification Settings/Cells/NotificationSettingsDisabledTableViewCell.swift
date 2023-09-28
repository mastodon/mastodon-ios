// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset
import MastodonLocalization


fileprivate extension CGFloat {
    static let padding: Self = 16
    static let appBadgeHeight: Self = 34
}

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
        notificationHintLabel.text = L10n.Scene.Settings.Notifications.Disabled.notificationHint
        notificationHintLabel.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16, weight: .regular))

        goToSettingsLabel = UILabel()
        goToSettingsLabel.textColor = Asset.Colors.Brand.blurple.color
        goToSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
        goToSettingsLabel.text = L10n.Scene.Settings.Notifications.Disabled.goToSettings
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
            appBadgeImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .padding),
            appBadgeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .padding),
            appBadgeImageView.heightAnchor.constraint(equalToConstant: .appBadgeHeight),
            appBadgeImageView.widthAnchor.constraint(equalTo: appBadgeImageView.heightAnchor),

            notificationHintLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .padding),
            notificationHintLabel.leadingAnchor.constraint(equalTo: appBadgeImageView.trailingAnchor, constant: .padding),
            contentView.trailingAnchor.constraint(equalTo: notificationHintLabel.trailingAnchor, constant: .padding),

            goToSettingsLabel.topAnchor.constraint(equalTo: notificationHintLabel.bottomAnchor, constant: .padding/2),
            goToSettingsLabel.leadingAnchor.constraint(equalTo: notificationHintLabel.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: goToSettingsLabel.trailingAnchor, constant: .padding),
            contentView.bottomAnchor.constraint(equalTo: goToSettingsLabel.bottomAnchor, constant: .padding),
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
