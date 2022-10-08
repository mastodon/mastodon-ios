//
//  ProfileFieldEditCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-22.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

protocol ProfileFieldEditCollectionViewCellDelegate: AnyObject {
    func profileFieldEditCollectionViewCell(_ cell: ProfileFieldEditCollectionViewCell, editButtonDidPressed button: UIButton)
}

final class ProfileFieldEditCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: ProfileFieldEditCollectionViewCellDelegate?
    
    static let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold, scale: .medium)
    static let removeButtonImage = UIImage(systemName: "minus.circle.fill", withConfiguration: symbolConfiguration)

    let containerStackView = UIStackView()

    let editButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.setImage(ProfileFieldEditCollectionViewCell.removeButtonImage, for: .normal)
        button.contentMode = .center
        button.tintColor = .systemRed
        return button
    }()
    
    // for editing
    let keyTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
        textField.textColor = Asset.Colors.Label.secondary.color
        textField.placeholder = L10n.Scene.Profile.Fields.Placeholder.label
        return textField
    }()
    
    // for editing
    let valueTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        textField.textColor = Asset.Colors.Label.primary.color
        textField.placeholder = L10n.Scene.Profile.Fields.Placeholder.content
        return textField
    }()

    let reorderBarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "line.horizontal.3")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)).withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileFieldEditCollectionViewCell {
    
    private func _init() {
        // containerStackView: H: - [ editButton | fieldContainer | reorderBarImageView ]
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
        ])
        
        let fieldContainer = UIStackView()
        fieldContainer.axis = .vertical
        containerStackView.addArrangedSubview(fieldContainer)
        
        fieldContainer.addArrangedSubview(keyTextField)
        fieldContainer.addArrangedSubview(valueTextField)
        
        containerStackView.addArrangedSubview(editButton)
        containerStackView.addArrangedSubview(fieldContainer)
        containerStackView.addArrangedSubview(reorderBarImageView)

        // editButton
        editButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        editButton.setContentHuggingPriority(.required - 1, for: .vertical)
        // reorderBarImageView
        reorderBarImageView.setContentHuggingPriority(.required - 1, for: .horizontal)
        reorderBarImageView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        editButton.addTarget(self, action: #selector(ProfileFieldEditCollectionViewCell.editButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension ProfileFieldEditCollectionViewCell {
    @objc private func editButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileFieldEditCollectionViewCell(self, editButtonDidPressed: sender)
    }
}

