//
//  SearchRecommendTagsCollectionViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import UIKit

class SearchRecommendTagsCollectionViewCell: UICollectionViewCell {
    let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let hashTagTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let peopleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let flameIconView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "flame.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold))!.withRenderingMode(.alwaysTemplate)
        imageView.image = image
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
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

extension SearchRecommendTagsCollectionViewCell {
    private func configure() {
        contentView.addSubview(backgroundImageView)
        backgroundImageView.constrain(toSuperviewEdges: nil)
        
        contentView.addSubview(hashTagTitleLabel)
        hashTagTitleLabel.pinTopLeft(padding: 16)
        
        contentView.addSubview(peopleLabel)
        peopleLabel.constrain([
            peopleLabel.constraint(toTop: contentView, constant: 46),
            peopleLabel.constraint(toLeading: contentView, constant: 16)
        ])
        
        contentView.addSubview(flameIconView)
        flameIconView.pinTopRight(padding: 16)
        
    }
}
