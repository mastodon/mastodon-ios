//
//  ProfileHeaderViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import UIKit

extension ProfileHeaderViewModel {
    func setupProfileFieldCollectionViewDiffableDataSource(
        collectionView: UICollectionView,
        profileFieldCollectionViewCellDelegate: ProfileFieldCollectionViewCellDelegate,
        profileFieldAddEntryCollectionViewCellDelegate: ProfileFieldAddEntryCollectionViewCellDelegate
    ) {
        let diffableDataSource = ProfileFieldSection.collectionViewDiffableDataSource(
            for: collectionView,
            profileFieldCollectionViewCellDelegate: profileFieldCollectionViewCellDelegate,
            profileFieldAddEntryCollectionViewCellDelegate: profileFieldAddEntryCollectionViewCellDelegate
        )
        
        diffableDataSource.reorderingHandlers.canReorderItem = { item in
            switch item {
            case .field:    return true
            default:        return false
            }
        }
        
        diffableDataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
        
            let items = transaction.finalSnapshot.itemIdentifiers
            var fieldValues: [ProfileFieldItem.FieldValue] = []
            for item in items {
                guard case let .field(field, _) = item else { continue }
                fieldValues.append(field)
            }
            self.editProfileInfo.fields.value = fieldValues
        }
        
        fieldDiffableDataSource = diffableDataSource
    }
}
