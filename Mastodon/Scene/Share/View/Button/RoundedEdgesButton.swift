//
//  RoundedEdgesButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-12.
//

import UIKit

final class RoundedEdgesButton: UIButton {
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = bounds.height * 0.5
    }
    
}
