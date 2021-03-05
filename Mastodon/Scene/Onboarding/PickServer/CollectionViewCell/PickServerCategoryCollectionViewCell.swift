//
//  PickServerCategoryCollectionViewCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit

class PickServerCategoryCollectionViewCell: UICollectionViewCell {
    
    var categoryView: PickServerCategoryView = {
        let view = PickServerCategoryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override var isSelected: Bool {
        didSet {
            categoryView.selected = isSelected
        }
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
        contentView.addSubview(categoryView)
        
        NSLayoutConstraint.activate([
            categoryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            contentView.bottomAnchor.constraint(equalTo: categoryView.bottomAnchor, constant: 10),
        ])
    }
}
