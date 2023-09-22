//
//  UIView.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import MastodonCore

extension UIView {
    public static var separatorLine: UIView {
        let line = UIView()
        line.backgroundColor = .separator
        return line
    }
    
    public static func separatorLineHeight(of view: UIView) -> CGFloat {
        return 1.0 / view.traitCollection.displayScale
    }
}
