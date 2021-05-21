//
//  KeyboardPreference.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-20.
//

import UIKit

extension UserDefaults {

    @objc dynamic var backKeyCommandPressDate: Date? {
        get {
            register(defaults: [#function: Date().timeIntervalSinceReferenceDate])
            return Date(timeIntervalSinceReferenceDate: double(forKey: #function))
        }
        set { self[#function] = newValue?.timeIntervalSinceReferenceDate }
    }

}
