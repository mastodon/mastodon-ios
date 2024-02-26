// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension UserDefaults {
    
    @objc public dynamic var defaultPostLanguage: String {
        get {
            return object(forKey: #function) as? String ?? Locale.current.language.languageCode?.identifier ?? "en"
        }
        set { self[#function] = newValue }
    }

}
