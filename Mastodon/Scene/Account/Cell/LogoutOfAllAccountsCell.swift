//
//  AddAccountTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-14.
//

import UIKit
import MetaTextKit
import MastodonAsset
import MastodonLocalization
import MastodonCore

final class LogoutOfAllAccountsCell: UITableViewCell {

    static let reuseIdentifier = "LogoutOfAllAccountsCell"

    let iconImageView: UIImageView = {
        let image = UIImage(systemName: "rectangle.portrait.and.arrow.forward")!
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemRed
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 22)
        label.textColor = .systemRed
        label.text = "Logout of all accounts"
        return label
    }()
    let separatorLine = UIView.separatorLine

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .secondarySystemGroupedBackground

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),
            iconImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        iconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        iconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)

        // layout the same placeholder UI from `AccountListTableViewCell`
        let placeholderLabelContainerStackView = UIStackView()
        placeholderLabelContainerStackView.axis = .vertical
        placeholderLabelContainerStackView.distribution = .equalCentering
        placeholderLabelContainerStackView.spacing = 2
        placeholderLabelContainerStackView.distribution = .fillProportionally
        placeholderLabelContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(placeholderLabelContainerStackView)
        NSLayoutConstraint.activate([
            placeholderLabelContainerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            placeholderLabelContainerStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            contentView.bottomAnchor.constraint(equalTo: placeholderLabelContainerStackView.bottomAnchor, constant: 10),
            iconImageView.heightAnchor.constraint(equalTo: placeholderLabelContainerStackView.heightAnchor, multiplier: 0.8).priority(.required - 10),
        ])
        let _nameLabel = MetaLabel(style: .accountListName)
        _nameLabel.configure(content: PlaintextMetaContent(string: " "))
        let _usernameLabel = MetaLabel(style: .accountListUsername)
        _usernameLabel.configure(content: PlaintextMetaContent(string: " "))
        placeholderLabelContainerStackView.addArrangedSubview(_nameLabel)
        placeholderLabelContainerStackView.addArrangedSubview(_usernameLabel)
        placeholderLabelContainerStackView.isHidden = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            contentView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            // iconImageView.heightAnchor.constraint(equalTo: titleLabel.heightAnchor, multiplier: 1.0).priority(.required - 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])

        accessibilityTraits.insert(.button)
    }

    required init?(coder: NSCoder) { fatalError() }
}

