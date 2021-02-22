//
//  UIView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/4.
//

import UIKit

// MARK: - Convinience view creation method
extension UIView {
    
    static var separatorLine: UIView {
        let line = UIView()
        line.backgroundColor = .separator
        return line
    }
    
    static func separatorLineHeight(of view: UIView) -> CGFloat {
        return 1.0 / view.traitCollection.displayScale
    }
    
    static var floatyButtonBottomMargin: CGFloat {
        return 16
    }
    
}

// MARK: - Convinience view appearance modification method
extension UIView {
    @discardableResult
    func applyCornerRadius(radius: CGFloat) -> Self {
        layer.masksToBounds = true
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        return self
    }
}
