//
//  Subscription.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import Foundation
import CoreDataStack // Needed until migration of push notification subscriptions has had time to occur
import MastodonSDK

extension Subscription {
    
    public var policy: Mastodon.API.Subscriptions.Policy? {
        return Mastodon.API.Subscriptions.Policy(rawValue: policyRaw)
    }
    
}

extension SubscriptionAlerts.Property {
    
    init(policy: Mastodon.API.Subscriptions.Policy) {
        switch policy {
        case .all:
            self.init(favourite: true, follow: true, followRequest: true, mention: true, poll: true, reblog: true)
        case .follower:
            self.init(favourite: true, follow: nil, followRequest: nil, mention: true, poll: true, reblog: true)
        case .followed:
            self.init(favourite: true, follow: true, followRequest: true, mention: true, poll: true, reblog: true)
        case .noone, ._other:
            self.init(favourite: nil, follow: nil, followRequest: nil, mention: nil, poll: nil, reblog: nil)
        }
    }
    
}
