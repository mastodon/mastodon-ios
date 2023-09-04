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
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        isPointerInteractionEnabled = true
    }
        
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        let radius = cornerRadius > .zero ? cornerRadius : bounds.height * 0.5
        layer.cornerRadius = radius
        pointerStyleProvider = { _, _, _ in
            UIPointerStyle(
                effect: .lift(UITargetedPreview(view: self)),
                shape: .roundedRect(self.frame, radius: radius)
            )
        }
    }
    
}
