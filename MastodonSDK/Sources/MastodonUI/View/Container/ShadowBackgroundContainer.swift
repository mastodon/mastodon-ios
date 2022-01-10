//
//  ShadowBackgroundContainer.swift
//  
//
//  Created by MainasuK on 2022-1-5.
//

import UIKit
import MastodonExtension

public final class ShadowBackgroundContainer: UIView {
    
    public var shadowAlpha: CGFloat = 0.25 {
        didSet { setNeedsLayout() }
    }
    
    public var shadowColor: UIColor = .black {
        didSet { setNeedsLayout() }
    }
    
    public var cornerRadius: CGFloat = 10 {
        didSet { setNeedsLayout() }
    }
    
    public let shadowLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ShadowBackgroundContainer {
    private func _init() {
        layer.insertSublayer(shadowLayer, at: 0)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        shadowLayer.frame = bounds
        shadowLayer.setupShadow(
            color: shadowColor,
            alpha: Float(shadowAlpha),
            x: 0,
            y: 1,
            blur: 2,
            spread: 0,
            roundedRect: bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
    }
}
