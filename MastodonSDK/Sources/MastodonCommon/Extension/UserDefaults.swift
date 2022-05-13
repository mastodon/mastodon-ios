//
//  UserDefaults.swift
//  
//
//  Created by MainasuK on 2022-4-29.
//

import Foundation

extension UserDefaults {
    public static let shared = UserDefaults(suiteName: AppName.groupID)!
}
