//
//  CustomEmojiPickerItemCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import UIKit
import SDWebImage

final class CustomEmojiPickerItemCollectionViewCell: UICollectionViewCell {
    
    static let itemSize = CGSize(width: 44, height: 44)

    let emojiImageView: SDAnimatedImageView = {
        let imageView = SDAnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override var isHighlighted: Bool {
        didSet {
            emojiImageView.alpha = isHighlighted ? 0.5 : 1.0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CustomEmojiPickerItemCollectionViewCell {
    
    private func _init() {
        emojiImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiImageView)
        emojiImageView.pinToParent()
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = "emoji"
    }
    
}
