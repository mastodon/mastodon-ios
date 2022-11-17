//
//  ProfileFieldSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import os
import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonMeta
import MastodonLocalization

enum ProfileFieldSection: Equatable, Hashable {
    case main
}

extension ProfileFieldSection {
    
    struct Configuration {
        weak var profileFieldCollectionViewCellDelegate: ProfileFieldCollectionViewCellDelegate?
        weak var profileFieldEditCollectionViewCellDelegate: ProfileFieldEditCollectionViewCellDelegate?
    }
    
    static func diffableDataSource(
        collectionView: UICollectionView,
        context: AppContext,
        configuration: Configuration
    ) -> UICollectionViewDiffableDataSource<ProfileFieldSection, ProfileFieldItem> {
        collectionView.register(ProfileFieldCollectionViewHeaderFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileFieldCollectionViewHeaderFooterView.headerReuseIdentifer)
        collectionView.register(ProfileFieldCollectionViewHeaderFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ProfileFieldCollectionViewHeaderFooterView.footerReuseIdentifer)
        
        let fieldCellRegistration = UICollectionView.CellRegistration<ProfileFieldCollectionViewCell, ProfileFieldItem> { cell, indexPath, item in
            let key, value: String
            let emojiMeta: MastodonContent.Emojis
            let verified: Bool

            switch item {
            case .field(field: let field):
                key = field.name.value
                value = field.value.value
                emojiMeta = field.emojiMeta
                verified = field.verifiedAt.value != nil
            case .createdAt(date: let date):
                key = L10n.Scene.Profile.Fields.joined
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                value = formatter.string(from: date)
                emojiMeta = [:]
                verified = false
            default: return
            }
            
            // set key
            let keyColor = verified ? Asset.Scene.Profile.About.bioAboutFieldVerifiedText.color : Asset.Colors.Label.secondary.color
            do {
                let mastodonContent = MastodonContent(content: key, emojis: emojiMeta)
                let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                cell.keyMetaLabel.textAttributes[.foregroundColor] = keyColor
                cell.keyMetaLabel.configure(content: metaContent)
            } catch {
                let content = PlaintextMetaContent(string: key)
//                cell.keyMetaLabel.textAttributes[.foregroundColor] = keyColor
                cell.keyMetaLabel.configure(content: content)
            }
            
            // set value
            let linkColor = verified ? Asset.Scene.Profile.About.bioAboutFieldVerifiedText.color : Asset.Colors.brand.color
            do {
                let mastodonContent = MastodonContent(content: value, emojis: emojiMeta)
                let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                cell.valueMetaLabel.linkAttributes[.foregroundColor] = linkColor
                cell.valueMetaLabel.configure(content: metaContent)
            } catch {
                let content = PlaintextMetaContent(string: value)
                cell.valueMetaLabel.linkAttributes[.foregroundColor] = linkColor
                cell.valueMetaLabel.configure(content: content)
            }
            
            // set background
            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColor = verified ? Asset.Scene.Profile.About.bioAboutFieldVerifiedBackground.color : UIColor.secondarySystemBackground
            cell.backgroundConfiguration = backgroundConfiguration
            
            // set checkmark and edit menu label
            if case .field(let field) = item, let verifiedAt = field.verifiedAt.value {
                cell.checkmark.isHidden = false
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                let dateString = formatter.string(from: verifiedAt)
                cell.checkmark.accessibilityLabel = L10n.Scene.Profile.Fields.Verified.long(dateString)
                cell.checkmarkPopoverString = L10n.Scene.Profile.Fields.Verified.short(dateString)
            } else {
                cell.checkmark.isHidden = true
                cell.checkmarkPopoverString = nil
            }

            cell.delegate = configuration.profileFieldCollectionViewCellDelegate
        }
        
        let editFieldCellRegistration = UICollectionView.CellRegistration<ProfileFieldEditCollectionViewCell, ProfileFieldItem> { cell, indexPath, item in
            guard case let .editField(field) = item else { return }
            
            cell.keyTextField.text = field.name.value
            cell.valueTextField.text = field.value.value
            
            NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: cell.keyTextField)
                .compactMap { $0.object as? UITextField }
                .map { $0.text ?? "" }
                .removeDuplicates()
                .assign(to: \.value, on: field.name)
                .store(in: &cell.disposeBag)
            
            NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: cell.valueTextField)
                .compactMap { $0.object as? UITextField }
                .map { $0.text ?? "" }
                .removeDuplicates()
                .assign(to: \.value, on: field.value)
                .store(in: &cell.disposeBag)
            
            // set background
            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColor = UIColor.secondarySystemBackground
            cell.backgroundConfiguration = backgroundConfiguration

            cell.delegate = configuration.profileFieldEditCollectionViewCellDelegate
        }
        
        let addEntryCellRegistration = UICollectionView.CellRegistration<ProfileFieldAddEntryCollectionViewCell, ProfileFieldItem> { cell, indexPath, item in
            guard case .addEntry = item else { return }
            
            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColorTransformer = .init { [weak cell] _ in
                guard let cell = cell else {
                    return .secondarySystemBackground
                }
                let state = cell.configurationState
                if state.isHighlighted || state.isSelected {
                    return .secondarySystemBackground.withAlphaComponent(0.5)
                } else {
                    return .secondarySystemBackground
                }
            }
            cell.backgroundConfiguration = backgroundConfiguration
        }

        let dataSource = UICollectionViewDiffableDataSource<ProfileFieldSection, ProfileFieldItem>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .field, .createdAt:
                return collectionView.dequeueConfiguredReusableCell(
                    using: fieldCellRegistration,
                    for: indexPath,
                    item: item
                )
            case .editField:
                return collectionView.dequeueConfiguredReusableCell(
                    using: editFieldCellRegistration,
                    for: indexPath,
                    item: item
                )
            case .addEntry:
                return collectionView.dequeueConfiguredReusableCell(
                    using: addEntryCellRegistration,
                    for: indexPath,
                    item: item
                )
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileFieldCollectionViewHeaderFooterView.headerReuseIdentifer, for: indexPath) as! ProfileFieldCollectionViewHeaderFooterView
                reusableView.frame.size.height = 20
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
