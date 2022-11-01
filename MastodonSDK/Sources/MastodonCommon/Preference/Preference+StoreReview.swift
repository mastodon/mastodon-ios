//
//  StoreReviewPreference.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-3.
//

import Foundation

extension UserDefaults {
    
    @objc public dynamic var processCompletedCount: Int {
        get {
            return integer(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
    @objc public dynamic var lastVersionPromptedForReview: String? {
        get {
            return string(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
}
