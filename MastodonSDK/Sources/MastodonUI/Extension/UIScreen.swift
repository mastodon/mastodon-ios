//
//  UIScreen.swift
//  
//
//  Created by Jed Fox on 2022-12-15.
//

import UIKit

extension UIScreen {
    public var pixelSize: CGFloat {
        if scale > 0 {
            return 1 / scale
        }
        // should never happen but just in case
        return 1
    }
}
