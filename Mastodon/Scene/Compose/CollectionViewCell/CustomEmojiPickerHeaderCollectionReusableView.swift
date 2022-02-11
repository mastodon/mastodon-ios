//
//  CustomEmojiPickerHeaderCollectionReusableView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class CustomEmojiPickerHeaderCollectionReusableView: UICollectionReusableView {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 12, weight: .bold))
        label.textColor = Asset.Colors.Label.secondary.color
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

extension CustomEmojiPickerHeaderCollectionReusableView {
    private func _init() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
