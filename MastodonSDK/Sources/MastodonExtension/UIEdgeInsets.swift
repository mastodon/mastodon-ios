//
//  UIEdgeInsets.swift
//  
//
//  Created by Jed Fox on 2022-11-24.
//

import UIKit

extension UIEdgeInsets {
    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
    public static func constant(_ offset: CGFloat) -> Self {
        UIEdgeInsets(top: offset, left: offset, bottom: offset, right: offset)
    }
}
