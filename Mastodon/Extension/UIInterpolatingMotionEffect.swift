//
//  UIInterpolatingMotionEffect.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import UIKit

extension UIInterpolatingMotionEffect {
    static func motionEffect(
        minX: CGFloat,
        maxX: CGFloat,
        minY: CGFloat,
        maxY: CGFloat
    ) -> UIMotionEffectGroup {
        let motionEffectX = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x", type: .tiltAlongHorizontalAxis)
        motionEffectX.minimumRelativeValue = minX
        motionEffectX.maximumRelativeValue = maxX
        
        let motionEffectY = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y", type: .tiltAlongVerticalAxis)
        motionEffectY.minimumRelativeValue = minY
        motionEffectY.maximumRelativeValue = maxY
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [motionEffectX, motionEffectY]
        
        return motionEffectGroup
    }
}
