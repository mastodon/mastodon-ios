//
//  Setting.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension Setting {
    
//    var appearance: SettingsItem.AppearanceMode {
//        return SettingsItem.AppearanceMode(rawValue: appearanceRaw) ?? .automatic
//    }
    
    public var activeSubscription: Subscription? {
        return (subscriptions ?? Set())
            .sorted(by: { $0.activedAt > $1.activedAt })
            .first
    }
    
}
