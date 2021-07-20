//
//  PickServerCategoriesCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import os.log
import UIKit
import MastodonSDK

protocol PickServerCategoriesCellDelegate: AnyObject {
    func pickServerCategoriesCell(_ cell: PickServerCategoriesCell, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
}

final class PickServerCategoriesCell: UITableViewCell {
    
    weak var delegate: PickServerCategoriesCellDelegate?
    
    var diffableDataSource: UICollectionViewDiffableDataSource<CategoryPickerSection, CategoryPickerItem>?
        
    let metricView = UIView()
    
    let collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let view = ControlContainableCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.register(PickServerCategoryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: PickServerCategoryCollectionViewCell.self))
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.layer.masksToBounds = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        delegate = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension PickServerCategoriesCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color
        
        metricView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metricView)
        NSLayoutConstraint.activate([
            metricView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            metricView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            metricView.topAnchor.constraint(equalTo: contentView.topAnchor),
            metricView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            metricView.heightAnchor.constraint(equalToConstant: 80).priority(.defaultHigh),
        ])
        
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 80).priority(.defaultHigh),
        ])
        
        collectionView.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.collectionViewLayout.invalidateLayout()
    }

}

// MARK: - UICollectionViewDelegateFlowLayout
extension PickServerCategoriesCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: indexPath: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        delegate?.pickServerCategoriesCell(self, collectionView: collectionView, didSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        layoutIfNeeded()
        return UIEdgeInsets(top: 0, left: metricView.frame.minX - collectionView.frame.minX, bottom: 0, right: collectionView.frame.maxX - metricView.frame.maxX)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 80)
    }
    
}

extension PickServerCategoriesCell {

    override func accessibilityElementCount() -> Int {
        guard let diffableDataSource = diffableDataSource else { return 0 }
        return diffableDataSource.snapshot().itemIdentifiers.count
    }
    
    override func accessibilityElement(at index: Int) -> Any? {
        guard let item = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else { return nil }
        return item
    }
    
}
