//
//  RoundedEdgesButton.swift
//  MastodonUI
//
//  Created by MainasuK Cirno on 2021-3-12.
//

import UIKit

open class RoundedEdgesButton: UIButton {
    
    public var cornerRadius: CGFloat = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
        
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius > .zero ? cornerRadius : bounds.height * 0.5
    }
    
}
