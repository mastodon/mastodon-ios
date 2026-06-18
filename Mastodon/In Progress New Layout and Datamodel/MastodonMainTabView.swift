// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonUI
import SDWebImageSwiftUI
import MastodonAsset

struct MastodonMainTabView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.displayScale) private var displayScale
    
    @State private var navigator = MastodonTabViewRouter.shared
    @State private var avatarIconRenderer = AvatarIconRenderer.shared
   
    
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
                    // Profile is a special case because when sidebar is available we are showing the current profile as a navigation tab and any other logged-in accounts as actions, plus an add additional account action, but when sidebar is not available (.compact width), we only want to show the profile icon
                    switch sizeClass {
                    case .regular:
                        TabSection {
                            if let currentAuthBox = AuthenticationServiceProvider.shared.currentActiveUser.value, let currentAuthAccount = currentAuthBox.cachedAccount, let icon = avatarIconRenderer.prerenderedAccountAvatar(currentAuthBox.globallyUniqueUserIdentifier, displayScale: displayScale) {
                                Tab(value: tab) {
                                    Text(tab.title)
                                        .font(.largeTitle)
                                } label: {
                                    Label {
                                        Text(currentAuthAccount.displayName)
                                    } icon: {
                                        icon
                                    }
                                }
                            } else {
                                Tab(tab.title, systemImage: "person", value: tab) {
                                    Text(tab.title)
                                        .font(.largeTitle)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: tab.systemImage)
                                Text(tab.title)
                            }
                        }
                        .sectionActions {
                            ForEach(AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.filter({ $0.globallyUniqueUserIdentifier != AuthenticationServiceProvider.shared.currentActiveUser.value?.globallyUniqueUserIdentifier }), id: \.self.globallyUniqueUserIdentifier) { account in
                                Button {
                                } label: {
                                    Label {
                                        Text(account.cachedAccount?.displayName ?? "")
                                    } icon: {
                                        avatarIconRenderer.prerenderedAccountAvatar(account.globallyUniqueUserIdentifier, displayScale: displayScale) ?? Image(systemName: "app.dashed")
                                    }
                                }
                            }
                        }
                        
                    case .compact:
                        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                            Text(tab.title)
                                .font(.largeTitle)
                        }
                    @unknown default:
                        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                            Text(tab.title)
                                .font(.largeTitle)
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
    
    private func subtabsFor(_ tab: MastodonTabViewRouter.MastodonTab) -> [MastodonTabViewRouter.MastodonTab]? {
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

@MainActor
@Observable class AvatarIconRenderer {
    public static let shared = AvatarIconRenderer()
    public var displayScale: CGFloat = 1 {
        didSet {
            if oldValue != displayScale {
                accountAvatarIconsRendered.removeAll(keepingCapacity: true)
                currentRender?.1.cancel()
                currentRender = nil
            }
        }
    }
    public private(set) var accountAvatarIconsRendered = [ String : Image ]()
    
    private var accountAvatarImages = [ String : UIImage ]()
    private var renderQueue = [String]()
    private var currentRender: (String, Task<Void, Never>)?
    
    init() {
        loadAccountAvatars()
    }
    
    private func loadAccountAvatars() {
        for authBox in AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes {
            guard let avatarURL = authBox.cachedAccount?.avatarImageURL() else {
                return
            }
            SDWebImageManager.shared.loadImage(
                with: avatarURL,
                progress: nil) { image, _, _, _, _, _ in
                    guard let image else { return }
                    self.accountAvatarImages[authBox.globallyUniqueUserIdentifier] = image
                }
        }
    }
    
    func prerenderedAccountAvatar(_ accountGUID: String, displayScale: CGFloat) -> Image? {
        if displayScale != self.displayScale {
            self.displayScale = displayScale
        }
        if let prerendered = accountAvatarIconsRendered[accountGUID] {
            return prerendered
        } else if !renderQueue.contains(accountGUID) && currentRender?.0 != accountGUID {
            renderQueue.append(accountGUID)
            doNextRender()
        }
        return nil
    }
    
    private func doNextRender() {
        if currentRender == nil, !renderQueue.isEmpty {
            let nextRenderGUID = renderQueue.removeFirst()
            currentRender = (nextRenderGUID, Task {
                guard !Task.isCancelled else { return }
                guard let image = accountAvatarImages[nextRenderGUID] else { return }
                let avatarView = AvatarView(size: .small, borderStyle: .separator, avatarSource: .local(Image(uiImage: image)), goToProfile: {})
                let renderer = ImageRenderer(content: avatarView)
                renderer.scale = displayScale
                guard let rendered = renderer.uiImage else { return }
                accountAvatarIconsRendered[nextRenderGUID] = Image(uiImage: rendered)
            })
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
