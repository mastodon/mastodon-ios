//
//  UserDefaults.swift
//  AppShared
//
//  Created by MainasuK Cirno on 2021-4-27.
//

import UIKit

extension UserDefaults {
    public static let shared = UserDefaults(suiteName: AppName.groupID)!
}

