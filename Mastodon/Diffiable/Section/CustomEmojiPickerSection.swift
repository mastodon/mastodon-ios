//
//  CustomEmojiPickerSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import UIKit
import Kingfisher

enum CustomEmojiPickerSection: Equatable, Hashable {
    case emoji(name: String)
}

extension CustomEmojiPickerSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency
    ) -> UICollectionViewDiffableDataSource<CustomEmojiPickerSection, CustomEmojiPickerItem> {
        let dataSource = UICollectionViewDiffableDataSource<CustomEmojiPickerSection, CustomEmojiPickerItem>(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .emoji(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CustomEmojiPickerItemCollectionViewCell.self), for: indexPath) as! CustomEmojiPickerItemCollectionViewCell
                let placeholder = UIImage.placeholder(size: CustomEmojiPickerItemCollectionViewCell.itemSize, color: .systemFill)
                    .af.imageRounded(withCornerRadius: 4)
                cell.emojiImageView.kf.setImage(
                    with: URL(string: attribute.emoji.url),
                    placeholder: placeholder,
                    options: [
                        .transition(.fade(0.2))
                    ],
                    completionHandler: nil
                )
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
                    header.titlelabel.text = name
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
