//
//  CircleAvatarButton.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import UIKit

public final class CircleAvatarButton: AvatarButton {
    
    @Published public var needsHighlighted = false
    
    public var borderColor: UIColor = UIColor.systemFill
    public var borderWidth: CGFloat = 1.0
    
    public override func updateAppearance() {
        super.updateAppearance()
        
        layer.masksToBounds = true
        layer.cornerRadius = frame.width * 0.5
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
    
}
