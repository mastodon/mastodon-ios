//
//  ProfileAboutViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-22.
//

import os.log
import UIKit
import Combine
import MastodonSDK

extension ProfileAboutViewModel {
    
    func setupDiffableDataSource(
        collectionView: UICollectionView,
        profileFieldCollectionViewCellDelegate: ProfileFieldCollectionViewCellDelegate,
        profileFieldEditCollectionViewCellDelegate: ProfileFieldEditCollectionViewCellDelegate
    ) {
        let diffableDataSource = ProfileFieldSection.diffableDataSource(
            collectionView: collectionView,
            context: context,
            configuration: ProfileFieldSection.Configuration(
                profileFieldCollectionViewCellDelegate: profileFieldCollectionViewCellDelegate,
                profileFieldEditCollectionViewCellDelegate: profileFieldEditCollectionViewCellDelegate
            )
        )
        self.diffableDataSource = diffableDataSource

        diffableDataSource.reorderingHandlers.canReorderItem = { item -> Bool in
            switch item {
            case .editField:    return true
            default:            return false
            }
        }
        
        diffableDataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
        
            let items = transaction.finalSnapshot.itemIdentifiers
            var fields: [ProfileFieldItem.FieldValue] = []
            for item in items {
                guard case let .editField(field) = item else { continue }
                fields.append(field)
            }
            self.profileInfoEditing.fields = fields
        }
        
        
        var snapshot = NSDiffableDataSourceSnapshot<ProfileFieldSection, ProfileFieldItem>()
        snapshot.appendSections([.main])
        diffableDataSource.apply(snapshot)

        let fields = Publishers.CombineLatest3(
            $isEditing.removeDuplicates(),
            profileInfo.$fields.removeDuplicates(),
            profileInfoEditing.$fields.removeDuplicates()
        ).map { isEditing, displayFields, editingFields in
            isEditing ? editingFields : displayFields
        }


        Publishers.CombineLatest4(
            $isEditing.removeDuplicates(),
            $createdAt.removeDuplicates(),
            fields,
            $emojiMeta.removeDuplicates()
        )
        .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
        .sink { [weak self] isEditing, createdAt, fields, emojiMeta in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }

            var snapshot = NSDiffableDataSourceSnapshot<ProfileFieldSection, ProfileFieldItem>()
            snapshot.appendSections([.main])

            var items: [ProfileFieldItem] = [
                .createdAt(date: createdAt),
            ] + fields.map { field in
                if isEditing {
                    return ProfileFieldItem.editField(field: field)
                } else {
                    return ProfileFieldItem.field(field: field)
                }
            }

            if isEditing, fields.count < ProfileHeaderViewModel.maxProfileFieldCount {
                items.append(.addEntry)
            }

            snapshot.appendItems(items, toSection: .main)

            diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
        .store(in: &disposeBag)
    }
    
}
