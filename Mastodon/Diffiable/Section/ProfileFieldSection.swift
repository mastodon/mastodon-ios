//
//  ProfileFieldSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import os
import UIKit
import Combine

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
                
                let margin = max(0, collectionView.frame.width - collectionView.readableContentGuide.layoutFrame.width)
                cell.containerStackView.layoutMargins = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
                cell.separatorLineToMarginLeadingLayoutConstraint.constant = margin
                
                // set key
                cell.fieldView.titleActiveLabel.configure(field: field.name.value, emojiDict: attribute.emojiDict.value)
                cell.fieldView.titleTextField.text = field.name.value
                Publishers.CombineLatest(
                    field.name.removeDuplicates(),
                    attribute.emojiDict.removeDuplicates()
                )
                .receive(on: RunLoop.main)
                .sink { [weak cell] name, emojiDict in
                    guard let cell = cell else { return }
                    cell.fieldView.titleActiveLabel.configure(field: name, emojiDict: emojiDict)
                    cell.fieldView.titleTextField.text = name
                }
                .store(in: &cell.disposeBag)
                
                
                // set value
                cell.fieldView.valueActiveLabel.configure(field: field.value.value, emojiDict: attribute.emojiDict.value)
                cell.fieldView.valueTextField.text = field.value.value
                Publishers.CombineLatest(
                    field.value.removeDuplicates(),
                    attribute.emojiDict.removeDuplicates()
                )
                .receive(on: RunLoop.main)
                .sink { [weak cell] value, emojiDict in
                    guard let cell = cell else { return }
                    cell.fieldView.valueActiveLabel.configure(field: value, emojiDict: emojiDict)
                    cell.fieldView.valueTextField.text = value
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
                cell.fieldView.titleActiveLabel.isHidden = attribute.isEditing
                cell.fieldView.valueActiveLabel.isHidden = attribute.isEditing
                
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

                let margin = max(0, collectionView.frame.width - collectionView.readableContentGuide.layoutFrame.width)
                cell.containerStackView.layoutMargins = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
                cell.separatorLineToMarginLeadingLayoutConstraint.constant = margin

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
