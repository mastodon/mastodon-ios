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
        dependency: NeedsDependency
    ) -> UICollectionViewDiffableDataSource<CategoryPickerSection, CategoryPickerItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak dependency] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let _ = dependency else { return nil }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PickServerCategoryCollectionViewCell.self), for: indexPath) as! PickServerCategoryCollectionViewCell
            cell.categoryView.titleLabel.text = item.title
            cell.observe(\.isSelected, options: [.initial, .new]) { cell, _ in
                cell.categoryView.highlightedIndicatorView.alpha = cell.isSelected ? 1 : 0
                cell.categoryView.titleLabel.textColor = cell.isSelected ? Asset.Colors.Label.primary.color : Asset.Colors.Label.secondary.color
            }
            .store(in: &cell.observations)
            
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.accessibilityDescription
            
            return cell
        }
    }
}
