//
//  UIView.swift
//  
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit

extension UIView {
    public static var isZoomedMode: Bool {
        return UIScreen.main.scale != UIScreen.main.nativeScale
    }
}
