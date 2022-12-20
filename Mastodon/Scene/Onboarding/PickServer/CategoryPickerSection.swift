//
//  CategoryPickerSection.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import UIKit
import MastodonAsset
import MastodonLocalization

enum CategoryPickerSection: Equatable, Hashable {
    case main
}

extension CategoryPickerSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency,
        buttonDelegate: PickServerCategoryCollectionViewCellDelegate?
    ) -> UICollectionViewDiffableDataSource<CategoryPickerSection, CategoryPickerItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak dependency] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let _ = dependency else { return nil }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PickServerCategoryCollectionViewCell.reuseIdentifier, for: indexPath) as! PickServerCategoryCollectionViewCell

            cell.titleLabel.text = item.title
            cell.delegate = buttonDelegate
            
            let isLanguage = (item == .language(language: nil))
            if isLanguage {
                cell.chevron.isHidden = false
                cell.menuButton.isUserInteractionEnabled = true

            } else {
                cell.chevron.isHidden = true
                cell.menuButton.isUserInteractionEnabled = false
            }

            cell.observe(\.isSelected, options: [.initial, .new]) { cell, _ in

                let textColor: UIColor
                let backgroundColor: UIColor
                let borderColor: UIColor

                if cell.isSelected {
                    textColor = .white
                    backgroundColor = Asset.Colors.Brand.blurple.color
                    borderColor = Asset.Colors.Brand.blurple.color
                } else {
                    textColor = .label
                    backgroundColor = .clear
                    borderColor = .separator
                }

                cell.backgroundColor = backgroundColor
                cell.titleLabel.textColor = textColor
                cell.layer.borderColor = borderColor.cgColor
                cell.chevron.tintColor = textColor
            }
            .store(in: &cell.observations)
            
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.accessibilityDescription
            
            return cell
        }
    }
}
