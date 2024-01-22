//
//  ProfileFieldCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import UIKit
import Combine
import MetaTextKit
import MastodonAsset
import MastodonLocalization

protocol ProfileFieldCollectionViewCellDelegate: AnyObject {
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, metaLabel: MetaLabel, didSelectMeta meta: Meta)
}

final class ProfileFieldCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: ProfileFieldCollectionViewCellDelegate?

    // for custom emoji display
    let keyMetaLabel = MetaLabel(style: .profileFieldName)
    let valueMetaLabel = MetaLabel(style: .profileFieldValue)
    
    let checkmark: UIImageView
    var checkmarkPopoverString: String? = nil;
    let tapGesture = UITapGestureRecognizer();
    var editMenuInteraction: UIEditMenuInteraction!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }

    override init(frame: CGRect) {

        // Setup colors
        checkmark = UIImageView(image: Asset.Scene.Profile.About.verifiedCheckmark.image.withRenderingMode(.alwaysTemplate))
        checkmark.tintColor = Asset.Colors.Brand.blurple.color
        checkmark.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: frame)

        editMenuInteraction = UIEditMenuInteraction(delegate: self)

        // Setup gestures
        tapGesture.addTarget(self, action: #selector(ProfileFieldCollectionViewCell.didTapCheckmark(_:)))
        checkmark.addGestureRecognizer(tapGesture)
        checkmark.isUserInteractionEnabled = true
        checkmark.addInteraction(editMenuInteraction)

        // Setup Accessibility
        checkmark.isAccessibilityElement = true
        checkmark.accessibilityTraits = .none
        keyMetaLabel.accessibilityTraits = .none
        keyMetaLabel.linkDelegate = self
        valueMetaLabel.linkDelegate = self


        // containerStackView: V - [ metaContainer | plainContainer ]
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.axis = .vertical
        containerStackView.preservesSuperviewLayoutMargins = true

        contentView.addSubview(containerStackView)
        contentView.preservesSuperviewLayoutMargins = true

        // metaContainer: h - [ keyValueContainer | checkmark ]
        let metaContainer = UIStackView()
        metaContainer.axis = .horizontal
        metaContainer.spacing = 2
        metaContainer.alignment = .center

        // valueContainer: v - [ keyMetaLabel | valueMetaLabel ]
        let keyValueContainer = UIStackView()
        keyValueContainer.axis = .vertical
        keyValueContainer.alignment = .leading
        keyValueContainer.spacing = 2

        containerStackView.addArrangedSubview(metaContainer)
        keyValueContainer.addArrangedSubview(keyMetaLabel)
        keyValueContainer.addArrangedSubview(valueMetaLabel)

        metaContainer.addArrangedSubview(keyValueContainer)
        metaContainer.addArrangedSubview(checkmark)

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 11),
            checkmark.heightAnchor.constraint(equalToConstant: 22),
            checkmark.widthAnchor.constraint(equalTo: checkmark.heightAnchor),
        ])

        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("Just ... don't.") }

    //MARK: - Actions

    @objc public func didTapCheckmark(_ recognizer: UITapGestureRecognizer) {
        editMenuInteraction?.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: recognizer.location(in: checkmark)))
    }

    private var valueMetas: [(title: String, Meta)] {
        var result: [(title: String, Meta)] = []
        valueMetaLabel.textStorage.enumerateAttribute(NSAttributedString.Key("MetaAttributeKey.meta"), in: NSMakeRange(0, valueMetaLabel.textStorage.length)) { value, range, _ in
            if let value = value as? Meta {
                result.append((valueMetaLabel.textStorage.string.substring(with: range), value))
            }
        }
        return result
    }

    //MARK: - Accessibility
    override func accessibilityActivate() -> Bool {
        if let (_, meta) = valueMetas.first {
            delegate?.profileFieldCollectionViewCell(self, metaLabel: valueMetaLabel, didSelectMeta: meta)
            return true
        }
        return false
    }

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            let valueMetas = valueMetas
            if valueMetas.count < 2 { return nil }
            return valueMetas.compactMap { title, meta in
                guard let name = meta.accessibilityLabel else { return nil }
                return UIAccessibilityCustomAction(name: name) { [weak self] _ in
                    guard let self, let delegate = self.delegate else { return false }
                    delegate.profileFieldCollectionViewCell(self, metaLabel: self.valueMetaLabel, didSelectMeta: meta)
                    return true
                }
            }
        }
        set {}
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        checkmark.image = Asset.Scene.Profile.About.verifiedCheckmark.image.withRenderingMode(.alwaysTemplate)
    }
}

// MARK: - MetaLabelDelegate
extension ProfileFieldCollectionViewCell: MetaLabelDelegate {
    func metaLabel(_ metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        delegate?.profileFieldCollectionViewCell(self, metaLabel: metaLabel, didSelectMeta: meta)
    }
}

// MARK: UIEditMenuInteractionDelegate
extension ProfileFieldCollectionViewCell: UIEditMenuInteractionDelegate {
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        guard let editMenuLabel = checkmarkPopoverString else { return UIMenu(children: []) }
        return UIMenu(children: [UIAction(title: editMenuLabel) { _ in return }])
    }
    
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        return checkmark.frame
    }
}
