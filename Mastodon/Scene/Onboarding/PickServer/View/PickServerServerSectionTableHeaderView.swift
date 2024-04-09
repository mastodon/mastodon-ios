//
//  PickServerServerSectionTableHeaderView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-4.
//

import UIKit
import Tabman
import MastodonAsset
import MastodonUI
import MastodonLocalization
import MastodonCore

protocol PickServerServerSectionTableHeaderViewDelegate: AnyObject {
    func pickServerServerSectionTableHeaderView(_ headerView: PickServerServerSectionTableHeaderView, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
}

final class PickServerServerSectionTableHeaderView: UIView {
    
    static let collectionViewHeight: CGFloat = 36
    static let spacing: CGFloat = 16
    
    static let height: CGFloat = collectionViewHeight + spacing
    
    weak var delegate: PickServerServerSectionTableHeaderViewDelegate?

    var diffableDataSource: UICollectionViewDiffableDataSource<CategoryPickerSection, CategoryPickerItem>?
    
    static func createCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(88), heightDimension: .absolute(PickServerServerSectionTableHeaderView.collectionViewHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: itemSize.widthDimension, heightDimension: itemSize.heightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsetsReference = .readableContent
        section.interGroupSpacing = 16
        
        return UICollectionViewCompositionalLayout(section: section)
    }

    let collectionView: UICollectionView = {
        let collectionViewLayout = PickServerServerSectionTableHeaderView.createCollectionViewLayout()
        let view = ControlContainableCollectionView(
            frame: CGRect(origin: .zero, size: CGSize(width: 100, height: PickServerServerSectionTableHeaderView.collectionViewHeight)),
            collectionViewLayout: collectionViewLayout
        )
        view.register(PickServerCategoryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: PickServerCategoryCollectionViewCell.self))
        view.backgroundColor = .clear
        view.alwaysBounceVertical = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.layer.masksToBounds = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.invalidateIntrinsicContentSize()
    }
}

extension PickServerServerSectionTableHeaderView {
    private func _init() {
        preservesSuperviewLayoutMargins = true
        backgroundColor = Asset.Scene.Onboarding.background.color
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.preservesSuperviewLayoutMargins = true
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: PickServerServerSectionTableHeaderView.collectionViewHeight),
            bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: PickServerServerSectionTableHeaderView.spacing),
        ])

        collectionView.delegate = self
    }
}

// MARK: - UICollectionViewDelegate
extension PickServerServerSectionTableHeaderView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        FeedbackGenerator.shared.generate(.selectionChanged)

        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        delegate?.pickServerServerSectionTableHeaderView(self, collectionView: collectionView, didSelectItemAt: indexPath)
    }
}

extension PickServerServerSectionTableHeaderView {

    override func accessibilityElementCount() -> Int {
        guard let diffableDataSource = diffableDataSource else { return 0 }
        return diffableDataSource.snapshot().itemIdentifiers.count + 1
    }

    override func accessibilityElement(at index: Int) -> Any? {
        if let item = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) {
            return item
        } else {
            return nil
        }
    }

}

// MARK: - UITextFieldDelegate
extension PickServerServerSectionTableHeaderView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}
