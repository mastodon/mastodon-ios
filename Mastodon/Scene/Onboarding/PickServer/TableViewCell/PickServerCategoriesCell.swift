//
//  PickServerCategoriesCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import MastodonSDK

protocol PickServerCategoriesDataSource: class {
    func numberOfCategories() -> Int
    func category(at index: Int) -> PickServerViewModel.Category
    func selectedIndex() -> Int
}

protocol PickServerCategoriesDelegate: class {
    func pickServerCategoriesCell(didSelect index: Int)
}

final class PickServerCategoriesCell: UITableViewCell {
    
    weak var dataSource: PickServerCategoriesDataSource!
    weak var delegate: PickServerCategoriesDelegate!
    
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
        self.selectionStyle = .none
        backgroundColor = .clear
        
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
        collectionView.dataSource = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.collectionViewLayout.invalidateLayout()
    }

}

extension PickServerCategoriesCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        delegate.pickServerCategoriesCell(didSelect: indexPath.row)
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

extension PickServerCategoriesCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfCategories()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let category = dataSource.category(at: indexPath.row)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PickServerCategoryCollectionViewCell.self), for: indexPath) as! PickServerCategoryCollectionViewCell
        cell.category = category
        
        // Select the default category by default
        if indexPath.row == dataSource.selectedIndex() {
            // Use `[]` as the scrollPosition to avoid contentOffset change
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            cell.isSelected = true
        }
        return cell
    }
    
    
}

