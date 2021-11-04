//
//  CircleAvatarButton.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import UIKit

final class CircleAvatarButton: AvatarButton {
    
    @Published var needsHighlighted = false
    
    var borderColor: UIColor = UIColor.systemFill
    var borderWidth: CGFloat = 1.0
    
    override func updateAppearance() {
        super.updateAppearance()
        
        layer.masksToBounds = true
        layer.cornerRadius = frame.width * 0.5
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
    
}
