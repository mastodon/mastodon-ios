//
//  CircleAvatarButton.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import UIKit

final class CircleAvatarButton: AvatarButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = frame.width * 0.5
        layer.borderColor = UIColor.systemFill.cgColor
        layer.borderWidth = 1
    }
}
