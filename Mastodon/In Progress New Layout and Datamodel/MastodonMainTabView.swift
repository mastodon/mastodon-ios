// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct MastodonMainTabView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @State private var navigator = MastodonTabViewRouter.shared
    
    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            ForEach(navigator.tabs(forSizeClass: sizeClass), id: \.self) { tab in
                if let subtabs = subtabsFor(tab) {
                    TabSection {
                        ForEach(subtabs, id: \.self) { subtab in
                            Tab(subtab.title, systemImage: subtab.systemImage, value: subtab) {
                                Text(subtab.title)
                                    .font(.largeTitle)
                            }
                            .customizationID(subtab.id)
                            .customizationBehavior(subtab.customizationBehavior, for: .tabBar, .sidebar)
                            .defaultVisibility(subtab.defaultTabBarVisibility, for: .tabBar)
                        }
                    } header: {
                        HStack {
                            Image(systemName: tab.systemImage)
                            Text(tab.title)
                        }
                    }
                    .defaultVisibility(.hidden, for: .tabBar)
                } else if tab == .profile {
                    // Profile is a special case because we are showing the current profile as a navigation tab and any other logged-in accounts as actions, plus an add additional account action
                    TabSection {
                        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                            Text(tab.title)
                                .font(.largeTitle)
                        }
                    } header: {
                        HStack {
                            Image(systemName: tab.systemImage)
                            Text(tab.title)
                        }
                    }
                    .sectionActions {
                        Button {
                                
                        } label: {
                            Text("switch to other account")
                        }
                    }
                } else {
                    Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                        Text(tab.title)
                            .font(.largeTitle)
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
    
    func subtabsFor(_ tab: MastodonTabViewRouter.MastodonTab) -> [MastodonTabViewRouter.MastodonTab]? {
        switch tab {
        case .home, .explore, .compose, .notifications, .profile, .list, .hashtag:
            return nil
        case .lists:
            return [.list("alist"), .list("blist")]
        case .hashtags:
            return [.hashtag("ahashtag"), .hashtag("bhashtag")]
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
        case .lists:
            "Lists"
        case .hashtags:
            "Hashtags"
        case .list(let title):
            title
        case .hashtag(let hashtag):
            hashtag
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
        case .lists, .list:
            "list.star"
        case .hashtags, .hashtag:
            "number"
        }
    }
    
    var customizationBehavior: TabCustomizationBehavior {
        switch self {
        case .home, .explore, .compose, .notifications, .profile, .lists, .hashtags:
                .disabled
        case .list, .hashtag:
                .automatic
        }
    }
    
    var defaultTabBarVisibility: Visibility {
        switch self {
        case .home, .explore, .compose, .notifications, .profile:
                .visible
        case .lists, .hashtags, .list, .hashtag:
                .hidden
        }
    }
}
