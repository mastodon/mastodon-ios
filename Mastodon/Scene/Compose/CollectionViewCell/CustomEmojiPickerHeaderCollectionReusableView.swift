//
//  CustomEmojiPickerHeaderCollectionReusableView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import UIKit

final class CustomEmojiPickerHeaderCollectionReusableView: UICollectionReusableView {
    
    let titlelabel: UILabel = {
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
        titlelabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titlelabel)
        NSLayoutConstraint.activate([
            titlelabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titlelabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            titlelabel.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            titlelabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
