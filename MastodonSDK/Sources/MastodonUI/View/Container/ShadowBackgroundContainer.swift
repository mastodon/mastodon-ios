//
//  ShadowBackgroundContainer.swift
//  
//
//  Created by MainasuK on 2022-1-5.
//

import UIKit
import MastodonExtension

public final class ShadowBackgroundContainer: UIView {
    
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
            color: .black,
            alpha: 0.25,
            x: 0,
            y: 1,
            blur: 2,
            spread: 0,
            roundedRect: bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: 10, height: 10)
        )
    }
}
