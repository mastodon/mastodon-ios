//
//  PortraitAlertController.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-12-31.
//

import UIKit

class PortraitAlertController: UIAlertController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portraitOnPhone
    }
}
