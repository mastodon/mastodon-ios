// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

class SettingsTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SettingsTableViewCell"

    let iconImageView: UIImageView
    let iconImageBackgroundView: UIView
    let titleLabel: UILabel

    private let contentStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        iconImageBackgroundView = UIView()
        iconImageBackgroundView.addSubview(iconImageView)

        titleLabel = UILabel()

        contentStackView = UIStackView(arrangedSubviews: [iconImageBackgroundView, titleLabel])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 16

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentStackView)
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 8),
            contentView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 8),

            iconImageBackgroundView.heightAnchor.constraint(equalToConstant: 30),
            iconImageBackgroundView.widthAnchor.constraint(equalTo: iconImageBackgroundView.heightAnchor),

            iconImageView.centerYAnchor.constraint(equalTo: iconImageBackgroundView.centerYAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: iconImageBackgroundView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),

            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 12),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func update(with entry: SettingsEntry) {
        titleLabel.textColor = entry.textColor
        titleLabel.text = entry.title

        if let icon = entry.icon {
            iconImageView.image = icon
            iconImageBackgroundView.isHidden = false
        } else {
            iconImageBackgroundView.isHidden = true
        }

        iconImageBackgroundView.layer.cornerRadius = 5
        iconImageBackgroundView.backgroundColor = entry.iconBackgroundColor

        accessoryType = entry.accessoryType

    }
}


