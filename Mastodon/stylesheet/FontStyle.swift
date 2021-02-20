//
//  FontStyle.swift
//  Mastodon
//
//  Created by 高原 on 2021/2/20.
//

import UIKit

fileprivate extension UIFont.TextStyle {
    var masFont: UIFont {
        switch self {
        case .headline:
            return UIFont(descriptor: UIFont.CustomFontDescriptor.SFProText, size: 34).bolded
        default:
            return UIFont(descriptor: UIFont.CustomFontDescriptor.SFProText, size: 16)
        }
    }
}

extension UIFont {
    
    fileprivate struct CustomFontDescriptor {
        static var fontFamily = "Avenir"
        static var SFProText = UIFontDescriptor(name: "SFProText", size: 0)
    }

    /// Returns a bold version of `self`
    public var bolded: UIFont {
        return fontDescriptor.withSymbolicTraits(.traitBold)
            .map { UIFont(descriptor: $0, size: 0) } ?? self
    }

    /// Returns an italic version of `self`
    public var italicized: UIFont {
        return fontDescriptor.withSymbolicTraits(.traitItalic)
            .map { UIFont(descriptor: $0, size: 0) } ?? self
    }

    /// Returns a scaled version of `self`
    func scaled(scaleFactor: CGFloat) -> UIFont {
        let newDescriptor = fontDescriptor.withSize(fontDescriptor.pointSize * scaleFactor)
        return UIFont(descriptor: newDescriptor, size: 0)
    }
    
    class func preferredFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let masFontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return masFontMetrics.scaledFont(for: textStyle.masFont)
    }
}
