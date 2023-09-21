//
//  SubscriptionAlerts.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension SubscriptionAlerts.Property {
    
    init(policy: Mastodon.API.Subscriptions.Policy) {
        switch policy {
        case .all:
            self.init(favourite: true, follow: true, followRequest: true, mention: true, poll: true, reblog: true)
        case .follower:
            self.init(favourite: true, follow: nil, followRequest: nil, mention: true, poll: true, reblog: true)
        case .followed:
            self.init(favourite: true, follow: true, followRequest: true, mention: true, poll: true, reblog: true)
        case .none, ._other:
            self.init(favourite: nil, follow: nil, followRequest: nil, mention: nil, poll: nil, reblog: nil)
        }
    }
    
}
