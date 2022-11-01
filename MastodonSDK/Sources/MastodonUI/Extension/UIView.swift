//
//  UIView.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import MastodonCore

extension UIView {
    
    static let separatorColor: UIColor = {
        UIColor(dynamicProvider: { collection in
            switch collection.userInterfaceStyle {
            case .dark:
                return ThemeService.shared.currentTheme.value.separator
            default:
                return .separator
            }
        })
    }()
    
    
    public static var separatorLine: UIView {
        let line = UIView()
        line.backgroundColor = UIView.separatorColor
        return line
    }
    
    public static func separatorLineHeight(of view: UIView) -> CGFloat {
        return 1.0 / view.traitCollection.displayScale
    }
    
}
