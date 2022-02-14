//
//  TrendSectionHeaderCollectionReusableView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class TrendSectionHeaderCollectionReusableView: UICollectionReusableView {
    
    let container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()
    
    let primaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Search.Recommend.HashTag.title
        label.numberOfLines = 0
        return label
    }()
    
    let secondaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = L10n.Scene.Search.Recommend.HashTag.description
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TrendSectionHeaderCollectionReusableView {
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 16),
        ])
        
        container.addArrangedSubview(primaryLabel)
        container.addArrangedSubview(secondaryLabel)
    }
}
