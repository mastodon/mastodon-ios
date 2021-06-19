// ref: https://github.com/Adlai-Holler/ASDKPlaceholderTest/blob/eea9fa7cff2d16a57efb47d208422ea9b49a630a/ASDKPlaceholderTest/ASDisplayNodeSubclasses.swift

import Foundation
import AsyncDisplayKit
import UIKit

/**
 A node that shows a `UIActivityIndicatorView`. Does not support layer backing.
 Note: You must not change the style to or from `.WhiteLarge` after init, or the node's size will not update.
 */
class ActivityIndicatorNode: ASDisplayNode {

    private static let defaultSize = CGSize(width: 20, height: 20)
    private static let largeSize = CGSize(width: 37, height: 37)

    init(style: UIActivityIndicatorView.Style = .medium) {
        super.init()
        setViewBlock {
            UIActivityIndicatorView(style: style)
        }

        self.style.preferredSize = style == .large ? ActivityIndicatorNode.defaultSize : ActivityIndicatorNode.largeSize
    }

    var activityIndicatorView: UIActivityIndicatorView {
        return view as! UIActivityIndicatorView
    }

    override func didLoad() {
        super.didLoad()
        if animating {
            activityIndicatorView.startAnimating()
        }
        activityIndicatorView.color = color
        activityIndicatorView.hidesWhenStopped = hidesWhenStopped
    }

    /// Wrapper for `UIActivityIndicatorView.hidesWhenStopped`. NOTE: You must respect thread affinity.
    var hidesWhenStopped = true {
        didSet {
            if isNodeLoaded {
                assert(Thread.isMainThread)
                activityIndicatorView.hidesWhenStopped = hidesWhenStopped
            }
        }
    }

    /// Wrapper for `UIActivityIndicatorView.color`. NOTE: You must respect thread affinity.
    var color: UIColor? {
        didSet {
            if isNodeLoaded {
                assert(Thread.isMainThread)
                activityIndicatorView.color = color
            }
        }
    }

    /// Wrapper for `UIActivityIndicatorView.animating`. NOTE: You must respect thread affinity.
    var animating = false {
        didSet {
            if isNodeLoaded {
                assert(Thread.isMainThread)
                if animating {
                    activityIndicatorView.startAnimating()
                } else {
                    activityIndicatorView.stopAnimating()
                }
            }
        }
    }
}
