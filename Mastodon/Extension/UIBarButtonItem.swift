//
//  UIBarButtonItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import UIKit

extension UIBarButtonItem {

    static var activityIndicatorBarButtonItem: UIBarButtonItem {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        let barButtonItem = UIBarButtonItem(customView: activityIndicatorView)
        activityIndicatorView.startAnimating()
        return barButtonItem
    }
    
}
