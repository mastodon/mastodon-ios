//
//  RoundedEdgesButton.swift
//  MastodonUI
//
//  Created by MainasuK Cirno on 2021-3-12.
//

import UIKit

open class RoundedEdgesButton: UIButton {
        
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = bounds.height * 0.5
    }
    
}
