//
//  PickServerCategoryCollectionViewCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit

class PickServerCategoryCollectionViewCell: UICollectionViewCell {
        
    var observations = Set<NSKeyValueObservation>()
    
    var categoryView = PickServerCategoryView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        observations.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension PickServerCategoryCollectionViewCell {
    private func configure() {
        backgroundColor = .clear
        
        categoryView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoryView)
        NSLayoutConstraint.activate([
            categoryView.topAnchor.constraint(equalTo: contentView.topAnchor),
            categoryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: categoryView.bottomAnchor),
        ])
    }
}
