//
//  UserDefaults.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-26.
//

import Foundation

extension UserDefaults {
    static let shared = UserDefaults(suiteName: AppSharedName.groupID)!
}

extension UserDefaults {
    
    subscript<T: RawRepresentable>(key: String) -> T? {
        get {
            if let rawValue = value(forKey: key) as? T.RawValue {
                return T(rawValue: rawValue)
            }
            return nil
        }
        set { set(newValue?.rawValue, forKey: key) }
    }
    
    subscript<T>(key: String) -> T? {
        get { return value(forKey: key) as? T }
        set { set(newValue, forKey: key) }
    }
    
}
