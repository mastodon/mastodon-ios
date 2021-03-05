//
//  CategoryPickerSection.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import UIKit

enum CategoryPickerSection: Equatable, Hashable {
    case main
}

extension CategoryPickerSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency
    ) -> UICollectionViewDiffableDataSource<CategoryPickerSection, CategoryPickerItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PickServerCategoryCollectionViewCell.self), for: indexPath) as! PickServerCategoryCollectionViewCell
            switch item {
            case .all:
                cell.categoryView.titleLabel.font = .systemFont(ofSize: 17)
            case .category:
                cell.categoryView.titleLabel.font = .systemFont(ofSize: 28)
            }
            cell.categoryView.titleLabel.text = item.title
            return cell
        }
    }
}
