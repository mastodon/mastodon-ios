//
//  ComposeViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import TwitterTextEditor

extension ComposeViewModel {
    
    func setupDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency,
        textEditorViewTextAttributesDelegate: TextEditorViewTextAttributesDelegate,
        composeStatusAttachmentTableViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate,
        composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate,
        composeStatusNewPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate,
        composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate
    ) {
        let diffableDataSource = ComposeStatusSection.collectionViewDiffableDataSource(
            for: collectionView,
            dependency: dependency,
            managedObjectContext: context.managedObjectContext,
            composeKind: composeKind,
            textEditorViewTextAttributesDelegate: textEditorViewTextAttributesDelegate,
            composeStatusAttachmentTableViewCellDelegate: composeStatusAttachmentTableViewCellDelegate,
            composeStatusPollOptionCollectionViewCellDelegate: composeStatusPollOptionCollectionViewCellDelegate,
            composeStatusNewPollOptionCollectionViewCellDelegate: composeStatusNewPollOptionCollectionViewCellDelegate,
            composeStatusPollExpiresOptionCollectionViewCellDelegate: composeStatusPollExpiresOptionCollectionViewCellDelegate
        )

        diffableDataSource.reorderingHandlers.canReorderItem = { item in
            switch item {
            case .pollOption:       return true
            default:                return false
            }
        }
        
        // update reordered data source
        diffableDataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
        
            let items = transaction.finalSnapshot.itemIdentifiers
            var pollOptionAttributes: [ComposeStatusItem.ComposePollOptionAttribute] = []
            for item in items {
                guard case let .pollOption(attribute) = item else { continue }
                pollOptionAttributes.append(attribute)
            }
            self.pollOptionAttributes.value = pollOptionAttributes
        }
    
        
        self.diffableDataSource = diffableDataSource
        var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusSection, ComposeStatusItem>()
        snapshot.appendSections([.repliedTo, .status, .attachment, .poll])
        switch composeKind {
        case .reply(let statusObjectID):
            snapshot.appendItems([.replyTo(statusObjectID: statusObjectID)], toSection: .repliedTo)
            snapshot.appendItems([.input(replyToStatusObjectID: statusObjectID, attribute: composeStatusAttribute)], toSection: .repliedTo)
        case .post:
            snapshot.appendItems([.input(replyToStatusObjectID: nil, attribute: composeStatusAttribute)], toSection: .status)
        }
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
    
}
