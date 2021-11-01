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
    
    let lineChartView = LineChartView()
    
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

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? Asset.Colors.brandBlueDarken20.color : Asset.Colors.brandBlue.color
        }
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

        containerStackView.addArrangedSubview(hashtagTitleLabel)
        containerStackView.addArrangedSubview(peopleLabel)
        
        let lineChartContainer = UIView()
        lineChartContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lineChartContainer)
        NSLayoutConstraint.activate([
            lineChartContainer.topAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 12),
            lineChartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: lineChartContainer.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: lineChartContainer.bottomAnchor, constant: 12),
        ])
        lineChartContainer.layer.masksToBounds = true
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartContainer.addSubview(lineChartView)
        NSLayoutConstraint.activate([
            lineChartView.topAnchor.constraint(equalTo: lineChartContainer.topAnchor, constant: 4),
            lineChartView.leadingAnchor.constraint(equalTo: lineChartContainer.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: lineChartContainer.trailingAnchor),
            lineChartContainer.bottomAnchor.constraint(equalTo: lineChartView.bottomAnchor, constant: 4),
        ])
        
    }
    
    func config(with tag: Mastodon.Entity.Tag) {
        hashtagTitleLabel.text = "# " + tag.name
        guard let history = tag.history else {
            peopleLabel.text = ""
            return
        }
        
        let recentHistory = history.prefix(2)
        let peopleAreTalking = recentHistory.compactMap({ Int($0.accounts) }).reduce(0, +)
        let string = L10n.Scene.Search.Recommend.HashTag.peopleTalking(String(peopleAreTalking))
        peopleLabel.text = string
        
        lineChartView.data = history
            .sorted(by: { $0.day < $1.day })        // latest last
            .map { entry in
            guard let point = Int(entry.accounts) else {
                return .zero
            }
            return CGFloat(point)
        }
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
