//
//  ProfileFieldCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import MastodonAsset
import MastodonLocalization

protocol ProfileFieldCollectionViewCellDelegate: AnyObject {
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, metaLebel: MetaLabel, didSelectMeta meta: Meta)
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, didTapAction: ProfileFieldCollectionViewCellAction)
}

enum ProfileFieldCollectionViewCellAction {
    case Checkmark
}

final class ProfileFieldCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: ProfileFieldCollectionViewCellDelegate?

    // for custom emoji display
    let keyMetaLabel = MetaLabel(style: .profileFieldName)
    let valueMetaLabel = MetaLabel(style: .profileFieldValue)
    
    let checkmark = UIImageView(image: Asset.Editing.checkmark.image.withRenderingMode(.alwaysTemplate))
    let tapGesture = UITapGestureRecognizer();
    
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
        // Setup colors
        checkmark.tintColor = Asset.Scene.Profile.About.bioAboutFieldValidatedCheckmark.color;
        
        // Setup gestures
        tapGesture.addTarget(self, action: #selector(ProfileFieldCollectionViewCell.didTapCheckmark(_:)))
        checkmark.addGestureRecognizer(tapGesture)
        checkmark.isUserInteractionEnabled = true
        
        // containerStackView: V - [ metaContainer | plainContainer ]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        
        contentView.preservesSuperviewLayoutMargins = true
        containerStackView.preservesSuperviewLayoutMargins = true
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 11),
        ])
        
        // metaContainer: V - [ keyMetaLabel | valueContainer ]
        let metaContainer = UIStackView()
        metaContainer.axis = .vertical
        metaContainer.spacing = 2
        containerStackView.addArrangedSubview(metaContainer)
        
        // valueContainer: H - [ valueMetaLabel | checkmark ]
        let valueContainer = UIStackView()
        valueContainer.axis = .horizontal
        valueContainer.spacing = 2
        
        metaContainer.addArrangedSubview(keyMetaLabel)
        valueContainer.addArrangedSubview(valueMetaLabel)
        valueContainer.addArrangedSubview(checkmark)
        metaContainer.addArrangedSubview(valueContainer)
        
        keyMetaLabel.linkDelegate = self
        valueMetaLabel.linkDelegate = self
    }
    
    @objc public func didTapCheckmark(_: UITapGestureRecognizer) {
        delegate?.profileFieldCollectionViewCell(self, didTapAction: .Checkmark)
    }
    
}

// MARK: - MetaLabelDelegate
extension ProfileFieldCollectionViewCell: MetaLabelDelegate {
    func metaLabel(_ metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileFieldCollectionViewCell(self, metaLebel: metaLabel, didSelectMeta: meta)
    }
}
