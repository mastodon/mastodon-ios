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
}

final class ProfileFieldCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: ProfileFieldCollectionViewCellDelegate?

    // for custom emoji display
    let keyMetaLabel = MetaLabel(style: .profileFieldName)
    let valueMetaLabel = MetaLabel(style: .profileFieldValue)
    
    let checkmark = UIImageView(image: Asset.Editing.checkmark.image.withRenderingMode(.alwaysTemplate))
    var checkmarkPopoverString: String? = nil;
    let tapGesture = UITapGestureRecognizer();
    private var _editMenuInteraction: Any? = nil
    @available(iOS 16, *)
    fileprivate var editMenuInteraction: UIEditMenuInteraction {
        _editMenuInteraction = _editMenuInteraction ?? UIEditMenuInteraction(delegate: self)
        return _editMenuInteraction as! UIEditMenuInteraction
    }
    
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
        checkmark.tintColor = Asset.Scene.Profile.About.bioAboutFieldVerifiedText.color;
        
        // Setup gestures
        tapGesture.addTarget(self, action: #selector(ProfileFieldCollectionViewCell.didTapCheckmark(_:)))
        checkmark.addGestureRecognizer(tapGesture)
        checkmark.isUserInteractionEnabled = true
        if #available(iOS 16, *) {
            checkmark.addInteraction(editMenuInteraction)
        }
        
        // Setup Accessibility
        checkmark.isAccessibilityElement = true
        checkmark.accessibilityTraits = .none
        keyMetaLabel.accessibilityTraits = .none

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
    
    @objc public func didTapCheckmark(_ recognizer: UITapGestureRecognizer) {
        if #available(iOS 16, *) {
            editMenuInteraction.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: recognizer.location(in: checkmark)))
        } else {
            guard let editMenuLabel = checkmarkPopoverString else { return }

            self.isUserInteractionEnabled = true
            self.becomeFirstResponder()

            UIMenuController.shared.menuItems = [
                UIMenuItem(
                    title: editMenuLabel,
                    action: #selector(dismissVerifiedMenu)
                )
            ]
            UIMenuController.shared.showMenu(from: checkmark, rect: checkmark.bounds)
        }
    }
}

// UIMenuController boilerplate
@available(iOS, deprecated: 16, message: "Can be removed when target version is >=16 -- boilerplate to maintain compatibility with UIMenuController")
extension ProfileFieldCollectionViewCell {
    override var canBecomeFirstResponder: Bool { true }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(dismissVerifiedMenu) {
            return true
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    @objc public func dismissVerifiedMenu() {
        UIMenuController.shared.hideMenu()
    }
}

// MARK: - MetaLabelDelegate
extension ProfileFieldCollectionViewCell: MetaLabelDelegate {
    func metaLabel(_ metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileFieldCollectionViewCell(self, metaLebel: metaLabel, didSelectMeta: meta)
    }
}

// MARK: UIEditMenuInteractionDelegate
@available(iOS 16.0, *)
extension ProfileFieldCollectionViewCell: UIEditMenuInteractionDelegate {
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        guard let editMenuLabel = checkmarkPopoverString else { return UIMenu(children: []) }
        return UIMenu(children: [UIAction(title: editMenuLabel) { _ in return }])
    }
    
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        return checkmark.frame
    }
}
