//
//  UITabBarController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-31.
//

import UIKit

extension UITabBarController {
    open override var childForStatusBarStyle: UIViewController? {
        return selectedViewController
    }
}
