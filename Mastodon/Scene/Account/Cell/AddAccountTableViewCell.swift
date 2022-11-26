//
//  AddAccountTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-14.
//

import UIKit
import Combine
import MetaTextKit
import MastodonAsset
import MastodonLocalization
import MastodonCore
import MastodonUI

final class AddAccountTableViewCell: UITableViewCell {
    
    private var _disposeBag = Set<AnyCancellable>()
    
    let iconImageView: UIImageView = {
        let image = UIImage(systemName: "plus.circle.fill")!
        let imageView = UIImageView(image: image)
        imageView.tintColor = Asset.Colors.Label.primary.color
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 22)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.AccountList.addAccount
        return label
    }()
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

extension AddAccountTableViewCell {

    private func _init() {
        backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
            }
            .store(in: &_disposeBag)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor, multiplier: 1.0).priority(.required - 1),
            iconImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).priority(.required - 1),
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

}
