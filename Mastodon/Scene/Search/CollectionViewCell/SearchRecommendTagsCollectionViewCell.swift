//
//  SearchRecommendTagsCollectionViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import MastodonSDK
import UIKit

class SearchRecommendTagsCollectionViewCell: UICollectionViewCell {
    let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
     
    let hashtagTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let peopleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    let flameIconView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "flame.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold))!.withRenderingMode(.alwaysTemplate)
        imageView.image = image
        imageView.tintColor = .white
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
    }
    
    private func configure() {
        backgroundColor = Asset.Colors.brandBlue.color
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        clipsToBounds = false
        layer.borderWidth = 2
        layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.distribution = .fill
        containerStackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.distribution = .fill

        hashtagTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        hashtagTitleLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        horizontalStackView.addArrangedSubview(hashtagTitleLabel)
        horizontalStackView.setContentHuggingPriority(.required - 1, for: .vertical)
        
        flameIconView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.addArrangedSubview(flameIconView)
        

        containerStackView.addArrangedSubview(horizontalStackView)
        peopleLabel.translatesAutoresizingMaskIntoConstraints = false
        peopleLabel.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        containerStackView.addArrangedSubview(peopleLabel)
        containerStackView.setCustomSpacing(SearchViewController.hashtagPeopleTalkingLabelTop, after: horizontalStackView)
    }
    
    func config(with tag: Mastodon.Entity.Tag) {
        hashtagTitleLabel.text = "# " + tag.name
        guard let historys = tag.history else {
            peopleLabel.text = ""
            return
        }
        
        let recentHistory = historys.prefix(2)
        let peopleAreTalking = recentHistory.compactMap({ Int($0.accounts) }).reduce(0, +)
        let string = L10n.Scene.Search.Recommend.HashTag.peopleTalking(String(peopleAreTalking))
        peopleLabel.text = string

    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchRecommendTagsCollectionViewCell_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchRecommendTagsCollectionViewCell()
                cell.hashtagTitleLabel.text = "# test"
                cell.peopleLabel.text = "128 people are talking"
                return cell
            }
            .previewLayout(.fixed(width: 228, height: 130))
        }
    }
    
    static var previews: some View {
        Group {
            controls.colorScheme(.light)
            controls.colorScheme(.dark)
        }
        .background(Color.gray)
    }
}

#endif
