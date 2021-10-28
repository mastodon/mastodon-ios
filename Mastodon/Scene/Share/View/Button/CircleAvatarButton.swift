//
//  CircleAvatarButton.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import UIKit

final class CircleAvatarButton: AvatarButton {
    
    var borderColor: CGColor = UIColor.systemFill.cgColor
    var borderWidth: CGFloat = 1.0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = frame.width * 0.5
        layer.borderColor = borderColor
        layer.borderWidth = borderWidth
    }
}
