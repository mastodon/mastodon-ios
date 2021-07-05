//
//  ThemePreference.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit

extension UserDefaults {

    @objc dynamic var currentThemeNameRawValue: String {
        get {
            register(defaults: [#function: ThemeName.mastodon.rawValue])
            return string(forKey: #function) ?? ThemeName.mastodon.rawValue
        }
        set { self[#function] = newValue }
    }

}
