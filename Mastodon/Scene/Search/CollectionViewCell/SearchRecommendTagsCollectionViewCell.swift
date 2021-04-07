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
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let hashTagTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
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
        backgroundColor = Asset.Colors.brandBlue.color
        layer.cornerRadius = 8
        clipsToBounds = true
        
        contentView.addSubview(backgroundImageView)
        backgroundImageView.constrain(toSuperviewEdges: nil)
        
        contentView.addSubview(hashTagTitleLabel)
        hashTagTitleLabel.pin(top: 16, left: 16, bottom: nil, right: 42)
        
        contentView.addSubview(peopleLabel)
        peopleLabel.pinTopLeft(top: 46, left: 16)
        
        contentView.addSubview(flameIconView)
        flameIconView.pinTopRight(padding: 16)
    }
    
    func config(with tag: Mastodon.Entity.Tag) {
        hashTagTitleLabel.text = "# " + tag.name
        guard let historys = tag.history else {
            peopleLabel.text = ""
            return
        }
        var recentHistory = [Mastodon.Entity.History]()
        for history in historys {
            if Int(history.uses) == 0 {
                break
            } else {
                recentHistory.append(history)
            }
        }
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
                cell.hashTagTitleLabel.text = "# test"
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
