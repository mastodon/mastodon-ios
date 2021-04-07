//
//  UINavigationController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-31.
//

import UIKit

// This not works!
// SeeAlso: `AdaptiveStatusBarStyleNavigationController`
extension UINavigationController {
    open override var childForStatusBarStyle: UIViewController? {
        return visibleViewController
    }
}
