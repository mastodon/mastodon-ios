// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

@MainActor
@Observable class MastodonTabViewRouter {
    
    public static let shared = MastodonTabViewRouter()
    
    enum MastodonTab: Identifiable {
        case home
        case explore
        case compose
        case notifications
        case profile
        
        var id: String {
            switch self {
            case .home: "home"
            case .explore: "explore"
            case .compose: "compose"
            case .notifications: "notifications"
            case .profile: "profile"
            }
        }
    }
    
    var selectedTab: MastodonTab = .home
    
    private var navigationRouters = [ MastodonTab : MastodonNavigationRouter]()
    
    var tabs: [MastodonTab] = [.home, .explore, .compose, .notifications, .profile]
    
    public func show(_ destination: MastodonNavigationDestination, in tab: MastodonTab) {
        var router = navigationRouter(forTab: tab)
        router.push(destination)
    }
    
    public func navigationRouter(forTab tab: MastodonTab) -> MastodonNavigationRouter {
        if let existing = navigationRouters[tab] {
            return existing
        }
        let freshRouter = MastodonNavigationRouter(navigationType: .swiftUI(legacyPresenter: nil))
        navigationRouters[tab] = freshRouter
        return freshRouter
    }
}
