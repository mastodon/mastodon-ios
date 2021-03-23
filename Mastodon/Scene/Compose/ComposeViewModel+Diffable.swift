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
        composeStatusNewPollOptionCollectionViewCellDelegate: ComposeStatusNewPollOptionCollectionViewCellDelegate
    ) {
        let diffableDataSource = ComposeStatusSection.collectionViewDiffableDataSource(
            for: collectionView,
            dependency: dependency,
            managedObjectContext: context.managedObjectContext,
            composeKind: composeKind,
            textEditorViewTextAttributesDelegate: textEditorViewTextAttributesDelegate,
            composeStatusAttachmentTableViewCellDelegate: composeStatusAttachmentTableViewCellDelegate,
            composeStatusPollOptionCollectionViewCellDelegate: composeStatusPollOptionCollectionViewCellDelegate,
            composeStatusNewPollOptionCollectionViewCellDelegate: composeStatusNewPollOptionCollectionViewCellDelegate
        )

        // Note: do not allow reorder due to the images display order following the upload time
        // diffableDataSource.reorderingHandlers.canReorderItem = { item in
        //     switch item {
        //     case .attachment:       return true
        //     default:                return false
        //     }
        //
        // }
        // diffableDataSource.reorderingHandlers.didReorder = { [weak self] transaction in
        //     guard let self = self else { return }
        //
        //     let items = transaction.finalSnapshot.itemIdentifiers
        //     var attachmentServices: [MastodonAttachmentService] = []
        //     for item in items {
        //         guard case let .attachment(attachmentService) = item else { continue }
        //         attachmentServices.append(attachmentService)
        //     }
        //     self.attachmentServices.value = attachmentServices
        // }
        //
        
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
