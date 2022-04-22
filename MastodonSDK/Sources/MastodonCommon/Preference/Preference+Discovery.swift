//
//  Preference+Discovery.swift
//  
//
//  Created by MainasuK on 2022-4-19.
//

import Foundation

extension UserDefaults {
    
    @objc public dynamic var discoveryIntroBannerNeedsHidden: Bool {
        get {
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }

}
