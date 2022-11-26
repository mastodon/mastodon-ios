//
//  CustomEmojiPickerInputView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import UIKit

final class CustomEmojiPickerInputView: UIInputView {
        
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(CustomEmojiPickerItemCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: CustomEmojiPickerItemCollectionViewCell.self))
        collectionView.register(CustomEmojiPickerHeaderCollectionReusableView.self, forSupplementaryViewOfKind: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self), withReuseIdentifier: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self))
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    let activityIndicatorView = UIActivityIndicatorView(style: .large)
    
    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CustomEmojiPickerInputView {
    private func _init() {
        allowsSelfSizing = true
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        collectionView.pinToParent()
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
    }
}

extension CustomEmojiPickerInputView {
    func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(CustomEmojiPickerItemCollectionViewCell.itemSize.width),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .flexible(4), top: .flexible(4), trailing: .flexible(0), bottom: .flexible(0))
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(CustomEmojiPickerItemCollectionViewCell.itemSize.height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5
        section.contentInsetsReference = .readableContent
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)

        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(44)),
            elementKind: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self),
            alignment: .top)
        // sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension CustomEmojiPickerInputView: UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool {
        return true
    }
}
