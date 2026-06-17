// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct MastodonMainTabView: View {
    
    @State private var navigator = MastodonTabViewRouter.shared
    
    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            ForEach(navigator.tabs, id: \.self) { tab in
                // TODO: remove obsolete Tab and then remove the unnecessary SwiftUI prefix here
                SwiftUI.Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    Text(tab.title)
                        .font(.largeTitle)
                }
            }
        }
    }
    
}

extension MastodonTabViewRouter.MastodonTab {
    var title: String {
        switch self {
        case .home:
            "Home"
        case .explore:
            "Explore"
        case .compose:
            "Compose"
        case .notifications:
            "Notifications"
        case .profile:
            "Profile"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .explore:
            "binoculars"
        case .compose:
            "square.and.pencil"
        case .notifications:
            "bell"
        case .profile:
            "person"
        }
    }
}
