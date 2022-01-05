//
//  CALayer.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-26.
//

import UIKit

extension CALayer {
    
    public func setupShadow(
        color: UIColor = .black,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0,
        roundedRect: CGRect? = nil,
        byRoundingCorners corners: UIRectCorner? = nil,
        cornerRadii: CGSize? = nil
    ) {
        // assert(roundedRect != .zero)
        shadowColor        = color.cgColor
        shadowOpacity      = alpha
        shadowOffset       = CGSize(width: x, height: y)
        shadowRadius       = blur / 2
        rasterizationScale = UIScreen.main.scale
        shouldRasterize    = true
        masksToBounds      = false
        
        guard let roundedRect = roundedRect,
              let corners = corners,
              let cornerRadii = cornerRadii else {
            return
        }
        
        if spread == 0 {
            shadowPath = UIBezierPath(roundedRect: roundedRect, byRoundingCorners: corners, cornerRadii: cornerRadii).cgPath
        } else {
            let rect = roundedRect.insetBy(dx: -spread, dy: -spread)
            shadowPath = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: cornerRadii).cgPath
        }
    }
    
    public func removeShadow() {
        shadowRadius = 0
    }
   
}
