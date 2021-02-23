//
//  UITapGestureRecognizer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/19.
//

import UIKit

extension UITapGestureRecognizer {
    
    static var singleTapGestureRecognizer: UITapGestureRecognizer {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        return tapGestureRecognizer
    }
    
    static var doubleTapGestureRecognizer: UITapGestureRecognizer {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 2
        tapGestureRecognizer.numberOfTouchesRequired = 1
        return tapGestureRecognizer
    }
    
}
