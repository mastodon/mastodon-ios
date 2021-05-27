//
//  ProfileFieldCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import os.log
import UIKit
import Combine
import ActiveLabel

protocol ProfileFieldCollectionViewCellDelegate: AnyObject {
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, editButtonDidPressed button: UIButton)
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity)
}

final class ProfileFieldCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: ProfileFieldCollectionViewCellDelegate?
    
    static let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold, scale: .medium)
    static let removeButtonItem = UIImage(systemName: "minus.circle.fill", withConfiguration: symbolConfiguration)
    
    let containerStackView = UIStackView()
    
    let fieldView = ProfileFieldView()
    
    let editButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.setImage(ProfileFieldCollectionViewCell.removeButtonItem, for: .normal)
        button.contentMode = .center
        button.tintColor = .systemRed
        return button
    }()

    let reorderBarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "line.horizontal.3")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)).withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    
    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!
    let bottomSeparatorLine = UIView.separatorLine
    
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

extension ProfileFieldCollectionViewCell {
    
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
        containerStackView.addArrangedSubview(reorderBarImageView)
        
        editButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        editButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        reorderBarImageView.setContentHuggingPriority(.required - 1, for: .horizontal)
        reorderBarImageView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
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
        
        editButton.addTarget(self, action: #selector(ProfileFieldCollectionViewCell.editButtonDidPressed(_:)), for: .touchUpInside)
        
        fieldView.valueActiveLabel.delegate = self
        
        resetSeparatorLineLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        resetSeparatorLineLayout()
    }
    
}

extension ProfileFieldCollectionViewCell {
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

extension ProfileFieldCollectionViewCell {
    @objc private func editButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileFieldCollectionViewCell(self, editButtonDidPressed: sender)
    }
}



// MARK: - ActiveLabelDelegate
extension ProfileFieldCollectionViewCell: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileFieldCollectionViewCell(self, activeLabel: activeLabel, didSelectActiveEntity: entity)
    }
}


#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ProfileFieldCollectionViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            ProfileFieldCollectionViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 44))
    }
    
}

#endif

