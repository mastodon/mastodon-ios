//
//  GradientBorderView.swift
//  Mastodon
//
//  Created by MainasuK on 2021-12-31.
//

import UIKit

final class GradientBorderView: UIView {
    
    let gradientLayer = CAGradientLayer()
    let maskLayer = CAShapeLayer()
    
    var cornerRadius: CGFloat = 9 {
        didSet { setNeedsLayout() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension GradientBorderView {
    private func _init() {
        isUserInteractionEnabled = false

        gradientLayer.frame = bounds

        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor,
        ]
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        layer.addSublayer(gradientLayer)
        
        // set blend mode to "Soft Light"
        layer.compositingFilter = "softLightBlendMode"
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bezierPath = UIBezierPath(rect: bounds)
        bezierPath.append(UIBezierPath(roundedRect: bounds.insetBy(dx: 3, dy: 3), cornerRadius: cornerRadius))
        
        maskLayer.fillRule = .evenOdd
        maskLayer.path = bezierPath.cgPath
        
        gradientLayer.frame = bounds
        gradientLayer.mask = maskLayer
    }
}
