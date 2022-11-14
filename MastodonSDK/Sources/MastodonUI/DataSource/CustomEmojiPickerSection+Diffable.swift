//
//  CustomEmojiPickerSection+Diffable.swift
//  
//
//  Created by MainasuK on 22/10/10.
//

import UIKit
import MastodonCore

extension CustomEmojiPickerSection {
    static func collectionViewDiffableDataSource(
        collectionView: UICollectionView,
        context: AppContext
    ) -> UICollectionViewDiffableDataSource<CustomEmojiPickerSection, CustomEmojiPickerItem> {
        let dataSource = UICollectionViewDiffableDataSource<CustomEmojiPickerSection, CustomEmojiPickerItem>(collectionView: collectionView) { [weak context] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let _ = context else { return nil }
            switch item {
            case .emoji(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CustomEmojiPickerItemCollectionViewCell.self), for: indexPath) as! CustomEmojiPickerItemCollectionViewCell
                let placeholder = UIImage.placeholder(size: CustomEmojiPickerItemCollectionViewCell.itemSize, color: .systemFill)
                    .af.imageRounded(withCornerRadius: 4)

                let isAnimated = !UserDefaults.shared.preferredStaticEmoji
                let url = URL(string:  isAnimated ? attribute.emoji.url : attribute.emoji.staticURL)
                cell.emojiImageView.sd_setImage(
                    with: url,
                    placeholderImage: placeholder,
                    options: [],
                    context: nil
                )
                cell.accessibilityLabel = attribute.emoji.shortcode
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak dataSource] collectionView, kind, indexPath -> UICollectionReusableView? in
            guard let dataSource = dataSource else { return nil }
            let sections = dataSource.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return nil }
            let section = sections[indexPath.section]

            switch kind {
            case String(describing: CustomEmojiPickerHeaderCollectionReusableView.self):
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self), for: indexPath) as! CustomEmojiPickerHeaderCollectionReusableView
                switch section {
                case .emoji(let name):
                    header.titleLabel.text = name
                }
                return header
            default:
                assertionFailure()
                return nil
            }
        }

        return dataSource
    }
}
