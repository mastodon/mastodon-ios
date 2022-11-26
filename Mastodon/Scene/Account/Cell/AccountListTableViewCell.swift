//
//  AccountListTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//

import UIKit
import Combine
import FLAnimatedImage
import MetaTextKit
import MastodonCore
import MastodonUI

final class AccountListTableViewCell: UITableViewCell {
    
    private var _disposeBag = Set<AnyCancellable>()
    var disposeBag = Set<AnyCancellable>()

    let avatarButton = CircleAvatarButton(frame: .zero)
    let nameLabel = MetaLabel(style: .accountListName)
    let usernameLabel = MetaLabel(style: .accountListUsername)
    let badgeButton = BadgeButton()
    let checkmarkImageView: UIImageView = {
        let image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        let imageView = UIImageView(image: image)
        return imageView
    }()
    let separatorLine = UIView.separatorLine
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        avatarButton.avatarImageView.image = nil
    }

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
        backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
            }
            .store(in: &_disposeBag)
        
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
        avatarButton.isAccessibilityElement = false

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
        ])

        labelContainerStackView.addArrangedSubview(nameLabel)
        labelContainerStackView.addArrangedSubview(usernameLabel)
        
        badgeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(badgeButton)
        NSLayoutConstraint.activate([
            badgeButton.leadingAnchor.constraint(equalTo: labelContainerStackView.trailingAnchor, constant: 4),
            badgeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            badgeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 16).priority(.required - 1),
            badgeButton.widthAnchor.constraint(equalTo: badgeButton.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        badgeButton.setContentHuggingPriority(.required - 10, for: .horizontal)
        badgeButton.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmarkImageView)
        NSLayoutConstraint.activate([
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.leadingAnchor.constraint(equalTo: badgeButton.trailingAnchor, constant: 12),
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
        ])
        checkmarkImageView.setContentHuggingPriority(.required - 9, for: .horizontal)
        checkmarkImageView.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
        
        avatarButton.isUserInteractionEnabled = false
        nameLabel.isUserInteractionEnabled = false
        usernameLabel.isUserInteractionEnabled = false
        badgeButton.isUserInteractionEnabled = false

        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),   // needs align to edge
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        
        badgeButton.setBadge(number: 0)
        checkmarkImageView.isHidden = true

        accessibilityTraits.insert(.button)
    }

}
