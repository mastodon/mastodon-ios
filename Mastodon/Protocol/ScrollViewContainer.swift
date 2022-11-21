//
//  ScrollViewContainer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/7.
//

import UIKit

protocol ScrollViewContainer: UIViewController {
    var scrollView: UIScrollView { get }
    func scrollToTop(animated: Bool)
}

extension ScrollViewContainer {
    func scrollToTop(animated: Bool) {
        scrollView.scrollToTop(animated: animated)
    }
}

extension UIScrollView {
    func scrollToTop(animated: Bool) {
        scrollRectToVisible(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)), animated: animated)
    }
}
