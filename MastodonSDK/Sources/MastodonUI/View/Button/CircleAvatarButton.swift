//
//  CircleAvatarButton.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import UIKit
import Combine

public final class CircleAvatarButton: AvatarButton {
    
    @Published public var needsHighlighted = false
    
    public var borderColor: UIColor = UIColor.systemFill
    public var borderWidth: CGFloat = 2.0

    public init() {
        super.init(avatarPlaceholder: .placeholder(color: .systemFill))
    }
    
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented")}
    
    public override func updateAppearance() {
        super.updateAppearance()
        
        layer.masksToBounds = true
        layer.cornerRadius = frame.width * 0.5
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
    
}
