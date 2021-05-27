//
//  ProfileFieldAddEntryCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-26.
//

import os.log
import UIKit
import Combine

protocol ProfileFieldAddEntryCollectionViewCellDelegate: AnyObject {
    func ProfileFieldAddEntryCollectionViewCellDidPressed(_ cell: ProfileFieldAddEntryCollectionViewCell)
}

final class ProfileFieldAddEntryCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: ProfileFieldAddEntryCollectionViewCellDelegate?
    
    let singleTagGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer

    
    static let symbolConfiguration = ProfileFieldCollectionViewCell.symbolConfiguration
    static let insertButtonImage = UIImage(systemName: "plus.circle.fill", withConfiguration: symbolConfiguration)

    let containerStackView = UIStackView()
    
    let fieldView = ProfileFieldView()
    
    let editButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.setImage(ProfileFieldAddEntryCollectionViewCell.insertButtonImage, for: .normal)
        button.contentMode = .center
        button.tintColor = .systemGreen
        return button
    }()
    
    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!
    let bottomSeparatorLine = UIView.separatorLine
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //resetStackView()
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

extension ProfileFieldAddEntryCollectionViewCell {
    
    private func _init() {
        containerStackView.axis = .horizontal
        containerStackView.spacing = 8
        
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerStackView.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        containerStackView.isLayoutMarginsRelativeArrangement = true
        
        containerStackView.addArrangedSubview(editButton)
        containerStackView.addArrangedSubview(fieldView)
        
        editButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        editButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        
        bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLineToMarginLeadingLayoutConstraint = bottomSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        separatorLineToEdgeTrailingLayoutConstraint = bottomSeparatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        separatorLineToMarginTrailingLayoutConstraint = bottomSeparatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor)

        addSubview(bottomSeparatorLine)
        NSLayoutConstraint.activate([
            separatorLineToMarginLeadingLayoutConstraint,
            bottomSeparatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)).priority(.defaultHigh),
        ])
        
        fieldView.titleTextField.text = L10n.Scene.Profile.Fields.addRow
        fieldView.valueActiveLabel.configure(field: " ", emojiDict: [:])
        
        addGestureRecognizer(singleTagGestureRecognizer)
        singleTagGestureRecognizer.addTarget(self, action: #selector(ProfileFieldAddEntryCollectionViewCell.singleTapGestureRecognizerHandler(_:)))
        
        editButton.addTarget(self, action: #selector(ProfileFieldAddEntryCollectionViewCell.addButtonDidPressed(_:)), for: .touchUpInside)
        
        resetSeparatorLineLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        resetSeparatorLineLayout()
    }
    
}

extension ProfileFieldAddEntryCollectionViewCell {

    @objc private func singleTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.ProfileFieldAddEntryCollectionViewCellDidPressed(self)
    }
    
    @objc private func addButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.ProfileFieldAddEntryCollectionViewCellDidPressed(self)
    }
    
}

extension ProfileFieldAddEntryCollectionViewCell {
    private func resetSeparatorLineLayout() {
        separatorLineToEdgeTrailingLayoutConstraint.isActive = false
        separatorLineToMarginTrailingLayoutConstraint.isActive = false
        
        if traitCollection.userInterfaceIdiom == .phone {
            // to edge
            NSLayoutConstraint.activate([
                separatorLineToEdgeTrailingLayoutConstraint,
            ])
        } else {
            if traitCollection.horizontalSizeClass == .compact {
                // to edge
                NSLayoutConstraint.activate([
                    separatorLineToEdgeTrailingLayoutConstraint,
                ])
            } else {
                // to margin
                NSLayoutConstraint.activate([
                    separatorLineToMarginTrailingLayoutConstraint,
                ])
            }
        }
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ProfileFieldAddEntryCollectionViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            ProfileFieldAddEntryCollectionViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 44))
    }
    
}

#endif

