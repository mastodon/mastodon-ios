//
//  Preference+Theme.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import MastodonExtension

public enum ThemeName: String, CaseIterable {
    case system
}

extension UserDefaults {

    @objc public dynamic var currentThemeNameRawValue: String {
        get {
            register(defaults: [#function: ThemeName.system.rawValue])
            return string(forKey: #function) ?? ThemeName.system.rawValue
        }
        set { self[#function] = newValue }
    }

}
