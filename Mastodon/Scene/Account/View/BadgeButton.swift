//
//  BadgeButton.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-16.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class BadgeButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension BadgeButton {
    private func _init() {
        titleLabel?.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .medium))
        setBackgroundColor(Asset.Colors.badgeBackground.color, for: .normal)
        setTitleColor(.white, for: .normal)
        
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = frame.height * 0.5
    }
    
    func setBadge(number: Int) {
        let number = min(99, max(0, number))
        setTitle("\(number)", for: .normal)
        self.isHidden = number == 0
        accessibilityLabel = L10n.A11y.Plural.Count.Unread.notification(number)
    }
}
