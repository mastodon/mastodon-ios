//
//  UIFont.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/1/28.
//

import UIKit

extension UIFont {

    // refs: https://stackoverflow.com/questions/26371024/limit-supported-dynamic-type-font-sizes
  static func preferredFont(withTextStyle textStyle: UIFont.TextStyle, maxSize: CGFloat) -> UIFont {
    // Get the descriptor
    let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

    // Return a font with the minimum size
    return UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maxSize))
  }
    
    public static func preferredMonospacedFont(withTextStyle textStyle: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        let fontDescription = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle).addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type:
                        kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector:
                        kMonospacedNumbersSelector
                ]
            ]
        ])
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: UIFont(descriptor: fontDescription, size: 0), compatibleWith: traitCollection)
    }

}
