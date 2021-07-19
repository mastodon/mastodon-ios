//
//  AppearancePreference.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-26.
//

import UIKit

extension UserDefaults {
    
    @objc dynamic var customUserInterfaceStyle: UIUserInterfaceStyle {
        get {
            register(defaults: [#function: UIUserInterfaceStyle.unspecified.rawValue])
            return UIUserInterfaceStyle(rawValue: integer(forKey: #function)) ?? .unspecified
        }
        set { self[#function] = newValue.rawValue }
    }

    @objc dynamic var preferredStaticAvatar: Bool {
        get {
            // default false
            // without set register to profile timeline performance
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }

}
