//
//  SearchRecommendCollectionHeader.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Foundation
import UIKit

class SearchRecommendCollectionHeader: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.primary.color
        label.font = .systemFont(ofSize: 20, weight: .semibold)
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
    
    let seeAllButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(Asset.Colors.brandBlue.color, for: .normal)
        button.setTitle(L10n.Scene.Search.Recommend.buttonText, for: .normal)
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
        addSubview(titleLabel)
        titleLabel.pinTopLeft(top: 31, left: 16)
        
        addSubview(descriptionLabel)
        descriptionLabel.constrain(toSuperviewEdges: UIEdgeInsets(top: 60, left: 16, bottom: 16, right: 16))
        
        addSubview(seeAllButton)
        seeAllButton.pinTopRight(top: 26, right: 16)
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
