//
//  ProfileFieldSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import os
import UIKit
import Combine
import MastodonMeta

enum ProfileFieldSection: Equatable, Hashable {
    case main
}

extension ProfileFieldSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        profileFieldCollectionViewCellDelegate: ProfileFieldCollectionViewCellDelegate,
        profileFieldAddEntryCollectionViewCellDelegate: ProfileFieldAddEntryCollectionViewCellDelegate
    ) -> UICollectionViewDiffableDataSource<ProfileFieldSection, ProfileFieldItem> {
        let dataSource = UICollectionViewDiffableDataSource<ProfileFieldSection, ProfileFieldItem>(collectionView: collectionView) {
            [
                weak profileFieldCollectionViewCellDelegate,
                weak profileFieldAddEntryCollectionViewCellDelegate
            ] collectionView, indexPath, item in
            switch item {
            case .field(let field, let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ProfileFieldCollectionViewCell.self), for: indexPath) as! ProfileFieldCollectionViewCell
                
                // set key
                do {
                    let mastodonContent = MastodonContent(content: field.name.value, emojis: attribute.emojiMeta.value)
                    let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                    cell.fieldView.titleMetaLabel.configure(content: metaContent)
                } catch {
                    let content = PlaintextMetaContent(string: field.name.value)
                    cell.fieldView.titleMetaLabel.configure(content: content)
                }
                cell.fieldView.titleTextField.text = field.name.value
                Publishers.CombineLatest(
                    field.name.removeDuplicates(),
                    attribute.emojiMeta.removeDuplicates()
                )
                .receive(on: RunLoop.main)
                .sink { [weak cell] name, emojiMeta in
                    guard let cell = cell else { return }
                    do {
                        let mastodonContent = MastodonContent(content: name, emojis: emojiMeta)
                        let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                        cell.fieldView.titleMetaLabel.configure(content: metaContent)
                    } catch {
                        let content = PlaintextMetaContent(string: name)
                        cell.fieldView.titleMetaLabel.configure(content: content)
                    }
                    // only bind label. The text field should only set once
                }
                .store(in: &cell.disposeBag)
                
                
                // set value
                do {
                    let mastodonContent = MastodonContent(content: field.value.value, emojis: attribute.emojiMeta.value)
                    let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                    cell.fieldView.valueMetaLabel.configure(content: metaContent)
                } catch {
                    let content = PlaintextMetaContent(string: field.value.value)
                    cell.fieldView.valueMetaLabel.configure(content: content)
                }
                cell.fieldView.valueTextField.text = field.value.value
                Publishers.CombineLatest(
                    field.value.removeDuplicates(),
                    attribute.emojiMeta.removeDuplicates()
                )
                .receive(on: RunLoop.main)
                .sink { [weak cell] value, emojiMeta in
                    guard let cell = cell else { return }
                    do {
                        let mastodonContent = MastodonContent(content: value, emojis: emojiMeta)
                        let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                        cell.fieldView.valueMetaLabel.configure(content: metaContent)
                    } catch {
                        let content = PlaintextMetaContent(string: value)
                        cell.fieldView.valueMetaLabel.configure(content: content)
                    }
                    // only bind label. The text field should only set once
                }
                .store(in: &cell.disposeBag)
                
                // bind editing
                if attribute.isEditing {
                    cell.fieldView.name
                        .removeDuplicates()
                        .receive(on: RunLoop.main)
                        .assign(to: \.value, on: field.name)
                        .store(in: &cell.disposeBag)
                    cell.fieldView.value
                        .removeDuplicates()
                        .receive(on: RunLoop.main)
                        .assign(to: \.value, on: field.value)
                        .store(in: &cell.disposeBag)
                }

                // setup editing state
                cell.fieldView.titleTextField.isHidden = !attribute.isEditing
                cell.fieldView.valueTextField.isHidden = !attribute.isEditing
                cell.fieldView.titleMetaLabel.isHidden = attribute.isEditing
                cell.fieldView.valueMetaLabel.isHidden = attribute.isEditing
                
                // set control hidden
                let isHidden = !attribute.isEditing
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update editing state: %s", ((#file as NSString).lastPathComponent), #line, #function, isHidden ? "true" : "false")
                cell.editButton.isHidden = isHidden
                cell.reorderBarImageView.isHidden = isHidden
                
                // update separator line
                cell.bottomSeparatorLine.isHidden = attribute.isLast

                cell.delegate = profileFieldCollectionViewCellDelegate
                
                return cell
                
            case .addEntry(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ProfileFieldAddEntryCollectionViewCell.self), for: indexPath) as! ProfileFieldAddEntryCollectionViewCell

                cell.bottomSeparatorLine.isHidden = attribute.isLast
                cell.delegate = profileFieldAddEntryCollectionViewCellDelegate
                
                return cell
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileFieldCollectionViewHeaderFooterView.headerReuseIdentifer, for: indexPath) as! ProfileFieldCollectionViewHeaderFooterView
                return reusableView
            case UICollectionView.elementKindSectionFooter:
                let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileFieldCollectionViewHeaderFooterView.footerReuseIdentifer, for: indexPath) as! ProfileFieldCollectionViewHeaderFooterView
                return reusableView
            default:
                return nil
            }
        }
        
        return dataSource
    }
}
