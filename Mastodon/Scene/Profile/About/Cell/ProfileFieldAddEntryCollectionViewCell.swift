//
//  ProfileFieldAddEntryCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-26.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import MetaTextKit
import MastodonCore
import MastodonUI

final class ProfileFieldAddEntryCollectionViewCell: UICollectionViewCell {

    static let symbolConfiguration = ProfileFieldEditCollectionViewCell.symbolConfiguration
    static let insertButtonImage = UIImage(systemName: "plus.circle.fill", withConfiguration: symbolConfiguration)

    let containerStackView = UIStackView()

    let editButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.setImage(ProfileFieldAddEntryCollectionViewCell.insertButtonImage, for: .normal)
        button.contentMode = .center
        button.tintColor = .systemGreen
        return button
    }()
    
    let primaryLabel = MetaLabel(style: .profileFieldValue)

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension ProfileFieldAddEntryCollectionViewCell {

    private func _init() {
        containerStackView.axis = .horizontal
        containerStackView.spacing = 8
        containerStackView.alignment = .center
        
        contentView.preservesSuperviewLayoutMargins = true
        containerStackView.preservesSuperviewLayoutMargins = true
        containerStackView.isLayoutMarginsRelativeArrangement = true

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
        ])
        containerStackView.isLayoutMarginsRelativeArrangement = true

        containerStackView.addArrangedSubview(editButton)
        containerStackView.addArrangedSubview(primaryLabel)

        editButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        editButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        editButton.isUserInteractionEnabled = false

        primaryLabel.configure(content: PlaintextMetaContent(string: L10n.Scene.Profile.Fields.addRow))
        primaryLabel.isUserInteractionEnabled = false
    }

}
