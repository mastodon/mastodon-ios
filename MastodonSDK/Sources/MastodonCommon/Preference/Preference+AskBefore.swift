// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension UserDefaults {
    
    @objc public dynamic var askBeforePostingWithoutAltText: Bool {
        get {
            return object(forKey: #function) as? Bool ?? true
        }
        set { self[#function] = newValue }
    }
    
    @objc public dynamic var askBeforeUnfollowingSomeone: Bool {
        get {
            return object(forKey: #function) as? Bool ?? true
        }
        set { self[#function] = newValue }
    }
    
    @objc public dynamic var askBeforeBoostingAPost: Bool {
        get {
            return object(forKey: #function) as? Bool ?? true
        }
        set { self[#function] = newValue }
    }
    
    @objc public dynamic var askBeforeDeletingAPost: Bool {
        get {
            return object(forKey: #function) as? Bool ?? true
        }
        set { self[#function] = newValue }
    }

}
