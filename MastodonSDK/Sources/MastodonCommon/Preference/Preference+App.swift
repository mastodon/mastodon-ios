//
//  AppPreference.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-8.
//

import UIKit

extension UserDefaults {

    @objc public dynamic var preferredUsingDefaultBrowser: Bool {
        get {
            register(defaults: [#function: false])
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }

}
