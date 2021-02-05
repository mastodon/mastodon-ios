//
//  UIView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/4.
//

import UIKit

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
