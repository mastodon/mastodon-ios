//
//  UIScrollView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/15.
//

import UIKit

extension UIScrollView {
    public enum ScrollDirection {
        case top
        case bottom
        case left
        case right
    }

    public func scroll(to direction: ScrollDirection, animated: Bool) {
        let offset: CGPoint
        switch direction {
        case .top:
            offset = CGPoint(x: contentOffset.x, y: -adjustedContentInset.top)
        case .bottom:
            offset = CGPoint(x: contentOffset.x, y: max(-adjustedContentInset.top, contentSize.height - frame.height + adjustedContentInset.bottom))
        case .left:
            offset = CGPoint(x: -adjustedContentInset.left, y: contentOffset.y)
        case .right:
            offset = CGPoint(x: max(-adjustedContentInset.left, contentSize.width - frame.width + adjustedContentInset.right), y: contentOffset.y)
        }
        setContentOffset(offset, animated: animated)
    }
}
