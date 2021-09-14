//
//  AccountListTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//

import UIKit
import FLAnimatedImage
import MetaTextKit

final class CircleAvatarButton: AvatarButton {
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.masksToBounds = true
        layer.cornerRadius = frame.width * 0.5
        layer.borderColor = UIColor.systemFill.cgColor
        layer.borderWidth = 1
    }
}

final class AccountListTableViewCell: UITableViewCell {

    let avatarButton = CircleAvatarButton()
    let nameLabel = MetaLabel(style: .accountListName)
    let usernameLabel = MetaLabel(style: .accountListUsername)
    let separatorLine = UIView.separatorLine

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension AccountListTableViewCell {

    private func _init() {
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            avatarButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarButton.heightAnchor.constraint(equalTo: avatarButton.widthAnchor, multiplier: 1.0).priority(.required - 1),
            avatarButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).priority(.required - 1),
        ])
        avatarButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        avatarButton.setContentHuggingPriority(.defaultLow, for: .vertical)

        let labelContainerStackView = UIStackView()
        labelContainerStackView.axis = .vertical
        labelContainerStackView.distribution = .equalCentering
        labelContainerStackView.spacing = 2
        labelContainerStackView.distribution = .fillProportionally
        labelContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelContainerStackView)
        NSLayoutConstraint.activate([
            labelContainerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            labelContainerStackView.leadingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: 10),
            contentView.bottomAnchor.constraint(equalTo: labelContainerStackView.bottomAnchor, constant: 10),
            avatarButton.heightAnchor.constraint(equalTo: labelContainerStackView.heightAnchor, multiplier: 0.8).priority(.required - 10),
            labelContainerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        labelContainerStackView.addArrangedSubview(nameLabel)
        labelContainerStackView.addArrangedSubview(usernameLabel)

        avatarButton.isUserInteractionEnabled = false
        nameLabel.isUserInteractionEnabled = false
        usernameLabel.isUserInteractionEnabled = false

        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
    }

}

// MARK: - AvatarConfigurableView
extension AccountListTableViewCell: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { CGSize(width: 30, height: 30) }
    static var configurableAvatarImageCornerRadius: CGFloat { 0 }
    var configurableAvatarImageView: FLAnimatedImageView? { avatarButton.avatarImageView }
}
