//
//  UIInterfaceOrientationMask.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-12-30.
//

import UIKit

extension UIInterfaceOrientationMask {
    public static var portraitOnPhone: Self {
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }
}
