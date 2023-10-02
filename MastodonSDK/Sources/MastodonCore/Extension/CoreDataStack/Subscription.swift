//
//  Subscription.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import Foundation
import CoreDataStack
import MastodonSDK

public typealias NotificationSubscription = Subscription

extension Subscription {
    
    public var policy: Mastodon.API.Subscriptions.Policy? {
        return Mastodon.API.Subscriptions.Policy(rawValue: policyRaw)
    }
    
}
