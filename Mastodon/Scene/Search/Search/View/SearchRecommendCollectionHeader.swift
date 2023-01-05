//
//  SearchRecommendCollectionHeader.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Foundation
import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

class SearchRecommendCollectionHeader: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.primary.color
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    let seeAllButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton(type: .custom)
        button.setTitleColor(Asset.Colors.brand.color, for: .normal)
        button.setTitle(L10n.Scene.Search.Recommend.buttonText, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension SearchRecommendCollectionHeader {
    private func configure() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.layoutMargins = UIEdgeInsets(top: 31, left: 16, bottom: 16, right: 16)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        containerStackView.pinToParent()
        
        let horizontalStackView = UIStackView()
        horizontalStackView.spacing = 8
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.distribution = .fill
        titleLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        horizontalStackView.addArrangedSubview(titleLabel)
        horizontalStackView.addArrangedSubview(seeAllButton)
        seeAllButton.setContentCompressionResistancePriority(.defaultHigh + 10, for: .horizontal)
        
        containerStackView.addArrangedSubview(horizontalStackView)
        containerStackView.addArrangedSubview(descriptionLabel)

    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchRecommendCollectionHeader_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchRecommendCollectionHeader()
                cell.titleLabel.text = "Trending in your timeline"
                cell.descriptionLabel.text = "Hashtags that are getting quite a bit of attention among people you follow"
                cell.seeAllButton.setTitle("See All", for: .normal)
                return cell
            }
            .previewLayout(.fixed(width: 320, height: 116))
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
