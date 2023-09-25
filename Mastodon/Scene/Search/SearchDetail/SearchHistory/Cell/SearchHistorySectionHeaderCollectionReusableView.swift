//
//  SearchHistorySectionHeaderCollectionReusableView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit
import MastodonAsset
import MastodonLocalization
import MastodonUI

protocol SearchHistorySectionHeaderCollectionReusableViewDelegate: AnyObject {
    func searchHistorySectionHeaderCollectionReusableView(_ searchHistorySectionHeaderCollectionReusableView: SearchHistorySectionHeaderCollectionReusableView, clearButtonDidPressed button: UIButton)
}

final class SearchHistorySectionHeaderCollectionReusableView: UICollectionReusableView {

    weak var delegate: SearchHistorySectionHeaderCollectionReusableViewDelegate?
    
    let primaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Search.Searching.recentSearch
        label.accessibilityTraits.insert(.header)
        return label
    }()
    
    let clearButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle(L10n.Scene.Search.Searching.clearAll, for: .normal)
        button.tintColor = Asset.Colors.Brand.blurple.color
        button.accessibilityLabel = L10n.Scene.Search.Searching.clear

        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    private func _init() {
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(primaryLabel)
        NSLayoutConstraint.activate([
            primaryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            primaryLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomAnchor.constraint(equalTo: primaryLabel.bottomAnchor, constant: 16).priority(.required - 1),
        ])
        primaryLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clearButton)
        NSLayoutConstraint.activate([
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.leadingAnchor.constraint(equalTo: primaryLabel.trailingAnchor, constant: 16),
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        clearButton.setContentHuggingPriority(.required - 10, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        
        clearButton.addTarget(self, action: #selector(SearchHistorySectionHeaderCollectionReusableView.clearButtonDidPressed(_:)), for: .touchUpInside)
    }

    @objc private func clearButtonDidPressed(_ sender: UIButton) {
        delegate?.searchHistorySectionHeaderCollectionReusableView(self, clearButtonDidPressed: sender)
    }
}
