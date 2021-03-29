//
//  ComposeViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine
import TwitterTextEditor
import MastodonSDK

extension ComposeViewModel {
    
    func setupDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency,
        customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel,
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
            customEmojiPickerInputViewModel: customEmojiPickerInputViewModel,
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
    
    func setupCustomEmojiPickerDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency
    ) {
        let diffableDataSource = CustomEmojiPickerSection.collectionViewDiffableDataSource(
            for: collectionView,
            dependency: dependency
        )
        self.customEmojiPickerDiffableDataSource = diffableDataSource
        
        customEmojiViewModel
            .sink { [weak self, weak diffableDataSource] customEmojiViewModel in
                guard let self = self else { return }
                guard let diffableDataSource = diffableDataSource else { return }
                guard let customEmojiViewModel = customEmojiViewModel else {
                    self.customEmojiViewModelSubscription = nil
                    let snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerSection, CustomEmojiPickerItem>()
                    diffableDataSource.apply(snapshot)
                    return
                }

                self.customEmojiViewModelSubscription = customEmojiViewModel.emojis
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self, weak diffableDataSource] emojis in
                        guard let _ = self else { return }
                        guard let diffableDataSource = diffableDataSource else { return }
                        var snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerSection, CustomEmojiPickerItem>()
                        let customEmojiSection = CustomEmojiPickerSection.emoji(name: customEmojiViewModel.domain.uppercased())
                        snapshot.appendSections([customEmojiSection])
                        let items: [CustomEmojiPickerItem] = {
                            var items = [CustomEmojiPickerItem]()
                            for emoji in emojis where emoji.visibleInPicker {
                                let attribute = CustomEmojiPickerItem.CustomEmojiAttribute(emoji: emoji)
                                let item = CustomEmojiPickerItem.emoji(attribute: attribute)
                                items.append(item)
                            }
                            return items
                        }()
                        snapshot.appendItems(items, toSection: customEmojiSection)
                        diffableDataSource.apply(snapshot)
                    }
            }
            .store(in: &disposeBag)
    }
    
}
