// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonUI
import SDWebImageSwiftUI
import MastodonAsset
import MastodonLocalization
import Combine
import WebKit
import SafariServices

extension EnvironmentValues {
    @Entry var sceneCoordinator: SceneCoordinator? = nil
}

struct MastodonMainTabView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.displayScale) private var displayScale
    @Environment(\.sceneCoordinator) private var sceneCoordinator
    
    @State private var authenticationObserver = AuthenticationObserver.shared
    @State private var tabViewRouter = MastodonTabViewRouter.current
    @State private var avatarIconRenderer = AvatarIconRenderer.shared
    @State private var showAccountSwitcher = false
    @State private var isSwitchingAccounts = false
   
    @State private var tabCustomization = TabViewCustomization()
    
    var body: some View {
        TabView(selection: $tabViewRouter.selectedTab) {
            ForEach(tabViewRouter.tabs(forSizeClass: sizeClass), id: \.self) { tab in
                if let subtabs = subtabsFor(tab) {
                    TabSection {
                        ForEach(subtabs, id: \.self) { subtab in
                            Tab(subtab.title, systemImage: subtab.systemImage, value: subtab) {
                                view(forTab: subtab)
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
                    // Profile is a special case because when sidebar is available we are showing the current profile as a navigation tab and settings as an action, but when sidebar is not available (.compact width), we only want to show the profile icon
                    switch sizeClass {
                    case .regular:
                        TabSection {
                            if let currentAuthBox = AuthenticationServiceProvider.shared.currentActiveUser.value, let currentAuthAccount = currentAuthBox.cachedAccount, let icon = avatarIconRenderer.prerenderedAccountAvatar(currentAuthBox.globallyUniqueUserIdentifier, style: .circular) {
                                Tab(value: tab) {
                                    view(forTab: tab)
                                } label: {
                                    Label {
                                        let handle = currentAuthAccount.acctWithDomain
                                        Text("@\(handle)")
                                    } icon: {
                                        icon
                                    }
                                }
                            } else {
                                Tab(tab.title, systemImage: "person", value: tab) {
                                    view(forTab: tab)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: tab.systemImage)
                                Text(tab.title)
                            }
                        }
                        .sectionActions {
                            settingsButton
                            alternateAccountButtons()
                        }
                        
                    case .compact, .none:
                        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                            view(forTab: tab)
                        }
                    @unknown default:
                        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                            view(forTab: tab)
                        }
                    }
                } else {
                    Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                        view(forTab: tab)
                    }
                    .customizationID(tab.id)
                    .customizationBehavior(tab.customizationBehavior, for: .tabBar, .sidebar)
                    .defaultVisibility(tab.defaultTabBarVisibility, for: .tabBar)
                }
            }
        }
        .id(tabViewRouter.userGUID)
        .environment(authenticationObserver)
        .environment(tabViewRouter)
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($tabCustomization)
        .fullScreenCover(isPresented:
                            Binding<Bool>(
                                get: { authenticationObserver.currentActiveUser == nil },
                                set: { _ in }
                            ), content: {
                                LegacyWelcomeFlowWrapper()
                            })
        .onChange(of: authenticationObserver.currentActiveUser, initial: true) { _, newValue in
            guard MastodonTabViewRouter.current.userGUID != newValue?.globallyUniqueUserIdentifier else { return }
            let newRouter = MastodonTabViewRouter.changeAuthenticatedUser(newValue)
            tabViewRouter = newRouter
        }
        .onChange(of: authenticationObserver.currentActiveUser?.globallyUniqueUserIdentifier, initial: true) { _, _ in
            loadTabCustomization(authenticationObserver.currentActiveUser)
        }
        .onChange(of: tabCustomization) { _, newValue in
            saveTabCustomization(newValue, forAuthBox: authenticationObserver.currentActiveUser)
        }
        .onChange(of: displayScale, initial: true) { _, newValue in
            AvatarIconRenderer.shared.displayScale = newValue
        }
        .onReceive(AuthenticationServiceProvider.shared.updateActiveUserAccountPublisher) { _ in
            // make sure the profile view has correct contents
            guard let authBox = authenticationObserver.currentActiveUser, let account = authBox.cachedAccount else { return }
            tabViewRouter.profileModel?.set(account: MastodonAccount.fromEntity(account, authenticatedDomain: authBox.domain), relationship: .isMe, navigator: tabViewRouter.navigationRouter(forTab: .profile))
        }
        .overlay {
            if isSwitchingAccounts {
                ZStack {
                    Color.secondary.opacity(0.8)
                    ProgressView().progressViewStyle(.circular)
                }
            }
        }
    }
    
    private func subtabsFor(_ tab: MastodonTabViewRouter.MastodonTab) -> [MastodonTabViewRouter.MastodonTab]? {
        switch tab {
        case .home, .localFeed, .explore, .notifications, .profile, .list, .hashtag:
            return nil
        case .lists:
            return tabViewRouter.lists.map { list in
                    .list(list)
            }
        case .hashtags:
            return tabViewRouter.followedHashtags.map { tag in
                    .hashtag(tag)
            }
        }
    }
    
    private func loadTabCustomization(_ authBox: MastodonAuthenticationBox?) {
        if let customizationKey = authBox?.tabCustomizationDefaultsKey, let tabCustomizationData = UserDefaults.standard.data(forKey: customizationKey) {
            tabCustomization = (try? JSONDecoder().decode(TabViewCustomization.self, from: tabCustomizationData)) ?? TabViewCustomization()
        } else {
            tabCustomization = TabViewCustomization()
        }
    }
    
    private func saveTabCustomization(_ customization: TabViewCustomization, forAuthBox authBox: MastodonAuthenticationBox?) {
        guard let authBox else { return }
        guard let data = try? JSONEncoder().encode(customization) else { return }
        UserDefaults.standard.set(data, forKey: authBox.tabCustomizationDefaultsKey)
    }
    
    @ViewBuilder private func view(forTab tab: MastodonTabViewRouter.MastodonTab) -> some View {
        switch tab {
        case .home:
            timelineNavigationStack(forTab: tab, includeTimelineSwitcherMenu: sizeClass == .compact)
             
        case .explore:
            @Bindable var navigationStackNavigator = tabViewRouter.navigationRouter(forTab: .explore)
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                ExploreRootView()
            }
            .environment(navigationStackNavigator)
            .environment(tabViewRouter.searchModel)
            .environment(tabViewRouter.discoveryModel)
                
        case .notifications:
            @Bindable var navigationStackNavigator = tabViewRouter.navigationRouter(forTab: tab)
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                let timelineModel = notificationsTimelineViewModel(scope: tabViewRouter.selectedNotificationsTimeline)
                TimelineListView()
                    .timelineEnvironment(timelineModel: timelineModel, contentConcealModel: .alwaysShow, filter: timelineModel.timelineQueryFilter, asyncRefreshModel: timelineModel.asyncRefreshViewModel)
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                            // picker as the center item
                            ToolbarItem(placement: .title) {
                                Picker("Scope", selection: $tabViewRouter.selectedNotificationsTimeline) {
                                    Text(L10n.Scene.Notification.Title.everything)
                                        .tag(NotificationsScope.everything)
                                    Text(L10n.Scene.Notification.Title.mentions)
                                        .tag(NotificationsScope.mentions)
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            
                            // filter button as the trailing item
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    self.showNotificationPolicySettings()
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                }
                                .buttonStyle(.plain)
                            }
                    }
                    .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                        navigationStackNavigator.destinationView(destination, sceneCoordinator: sceneCoordinator)
                    }
            }
            .environment(navigationStackNavigator)
            
        case .profile:
            @Bindable var navigationStackNavigator = tabViewRouter.navigationRouter(forTab: tab)
            let profileModel = profileViewModel()
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                ProfileView(wrapInSwiftUINavigationStack: false)
                    .profileEnvironment(profileModel, nestedScroll: NestedScrollInteractionViewModel())
                    .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                        navigationStackNavigator.destinationView(destination, sceneCoordinator: sceneCoordinator)
                    }
            }
            .environment(navigationStackNavigator)
            
        case .localFeed, .list, .hashtag:
            timelineNavigationStack(forTab: tab, includeTimelineSwitcherMenu: false) // these are only created as their own tabs in .regular size class, where the timeline switcher never appears
            
        case .lists, .hashtags:
            // these should never be called upon to actually produce a view, they are only used as sidebar sections for the actual views
            EmptyView()
        }
    }
    
    @ViewBuilder private var settingsButton: some View {
        Button {
            let currentTabNavigator = self.tabViewRouter.navigationRouter(forTab: self.tabViewRouter.selectedTab)
            let needsDismiss = showAccountSwitcher || currentTabNavigator.presentedSheet != nil
            if needsDismiss {
                showAccountSwitcher = false
                currentTabNavigator.dismissCurrentModal()
            }
            currentTabNavigator.presentSheet(.settings, afterDeconflictionDelay: needsDismiss)
        } label: {
            Label {
                Text(L10n.Common.Controls.Actions.settings)
            } icon: {
                Image(systemName: "gear")
            }
        }
    }
    
    @ViewBuilder private func modalComposeButton(forTab tab: MastodonTabViewRouter.MastodonTab) -> some View {
        let navigator = tabViewRouter.navigationRouter(forTab: tab)
        if let authBox = AuthenticationObserver.shared.currentActiveUser {
            Button {
                navigator.presentSheet(.modalCompose(.init(authenticationBox: authBox, composeContext: .composeStatus(quoting: nil), destination: .topLevel), tabViewRouter.currentDraftContentViewModel(authBox: authBox)), afterDeconflictionDelay: false)
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(.white)
                    .padding(standardPadding)
                    .background {
                        Circle()
                            .fill(Asset.Colors.accent.swiftUIColor)
                    }
            }
            .padding()
        }
    }
    
    @ViewBuilder private func alternateAccountButtons() -> some View {
        // List additional logged-in accounts
        ForEach(AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.filter({ $0.globallyUniqueUserIdentifier != AuthenticationServiceProvider.shared.currentActiveUser.value?.globallyUniqueUserIdentifier }), id: \.self.globallyUniqueUserIdentifier) { authBox in
            Button {
                self.switchTo(authBox)
            } label: {
                Label {
                    if let handle = authBox.cachedAccount?.acctWithDomain {
                        Text("@\(handle)")
                    } else {
                        Text(authBox.cachedAccount?.displayName ?? "")
                    }
                } icon: {
                    avatarIconRenderer.prerenderedAccountAvatar(authBox.globallyUniqueUserIdentifier, style: .circular) ?? Image(systemName: "app.dashed")
                }
                .padding(.horizontal)
                .padding(.vertical, tinySpacing)
            }
        }
        
        // Offer adding another account
        Button {
            let needsDismissCurrent = showAccountSwitcher
            if needsDismissCurrent {
                // must dismiss or the new modal presentation will not happen
                showAccountSwitcher = false
            }
            let needsTabSwitch = tabViewRouter.selectedTab != .home
            if needsTabSwitch {
                tabViewRouter.selectedTab = .home
            }
            tabViewRouter.navigationRouter(forTab: .home).presentSheet(.welcome, afterDeconflictionDelay: needsDismissCurrent || needsTabSwitch)
        } label: {
            Label {
                Text(L10n.Scene.AccountList.addAccount)
            } icon: {
                Image(systemName: "plus")
            }
            .padding(.horizontal)
            .padding(.vertical, tinySpacing)
        }
    }
    
    @ViewBuilder private func accountSwitcherView() -> some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if let currentAuthBox = AuthenticationServiceProvider.shared.currentActiveUser.value, let currentAuthAccount = currentAuthBox.cachedAccount, let icon = avatarIconRenderer.prerenderedAccountAvatar(currentAuthBox.globallyUniqueUserIdentifier, style: .circular) {
                    Button {
                        tabViewRouter.selectedTab = .profile
                        showAccountSwitcher = false
                    } label: {
                        let handle = currentAuthAccount.acctWithDomain
                        VStack {
                            icon
                            Text("@\(handle)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                settingsButton
                    .padding(.horizontal)
                Divider()
                alternateAccountButtons()
            }
            .padding()
        }
    }

    private func timelineViewModel(forTab tab: MastodonTabViewRouter.MastodonTab) -> TimelineListViewModel? {
        switch tab {
        case .home:
            if let model = tabViewRouter.homeTimelineModel {
                return model
            } else {
                let model = TimelineListViewModel(timeline: .homeTimeline, navigator: tabViewRouter.navigationRouter(forTab: .home), asyncRefreshViewModel: AsyncRefreshViewModel())
                tabViewRouter.homeTimelineModel = model
                return model
            }
            
        case .localFeed:
            if let model = tabViewRouter.customTimelineModels[tab] {
                return model
            } else {
                let model = TimelineListViewModel(timeline: .local, navigator: tabViewRouter.navigationRouter(forTab: tab), asyncRefreshViewModel: AsyncRefreshViewModel())
                tabViewRouter.customTimelineModels[tab] = model
                return model
            }
            
        case .list(let list):
            if let model = tabViewRouter.customTimelineModels[tab] {
                return model
            } else {
                let model = TimelineListViewModel(timeline: .list(list.id), navigator: tabViewRouter.navigationRouter(forTab: tab), asyncRefreshViewModel: AsyncRefreshViewModel())
                tabViewRouter.customTimelineModels[tab] = model
                return model
            }
        case .hashtag(let hashtag):
            if let model = tabViewRouter.customTimelineModels[tab] {
                return model
            } else {
                let model = TimelineListViewModel(timeline: .hashtag(hashtag, includeHeader: false), navigator: tabViewRouter.navigationRouter(forTab: tab), asyncRefreshViewModel: AsyncRefreshViewModel())
                tabViewRouter.customTimelineModels[tab] = model
                return model
            }
        default:
            return nil
        }
    }
    
    func profileViewModel() -> ProfileViewModel {
        if let model = tabViewRouter.profileModel {
            return model
        } else {
            let model = ProfileViewModel()
            if let authBox = authenticationObserver.currentActiveUser, let account = authBox.cachedAccount {
                model.set(account: MastodonAccount.fromEntity(account, authenticatedDomain: authBox.domain), relationship: .isMe, navigator: tabViewRouter.navigationRouter(forTab: .profile))
            }
            tabViewRouter.profileModel = model
            return model
        }
    }
    
    private func notificationsTimelineViewModel(scope: NotificationsScope) -> TimelineListViewModel {
        func newModel() -> TimelineListViewModel {
            let new = TimelineListViewModel(timeline: .notifications(scope: scope), navigator: tabViewRouter.navigationRouter(forTab: .notifications), asyncRefreshViewModel: AsyncRefreshViewModel())
            tabViewRouter.fetchFilteredNotificationsPolicy(andReloadFeed: false)
            return new
        }
        switch scope {
        case .everything:
            if let model = tabViewRouter.notificationsTimelineModelEverything {
                return model
            }
            let new = newModel()
            tabViewRouter.notificationsTimelineModelEverything = new
            return new
        case .mentions:
            if let model = tabViewRouter.notificationsTimelineModelMentions {
                return model
            }
            let new = newModel()
            tabViewRouter.notificationsTimelineModelMentions = new
            return new
        case .fromRequest:
            assertionFailure()
            return newModel()
        }
    }
    
    private func switchTo(_ authBox: MastodonAuthenticationBox) {
        isSwitchingAccounts = true
        let needsDismiss = showAccountSwitcher
        if needsDismiss {
            showAccountSwitcher = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) { // this delay gives the modals time to dismiss, making the transition feel less abrupt
            AuthenticationServiceProvider.shared.activateAuthentication(authBox)
            self.isSwitchingAccounts = false
        }
    }
    
    private func showNotificationPolicySettings() {
        guard let policy = notificationsTimelineViewModel(scope: tabViewRouter.selectedNotificationsTimeline).filteredNotificationsViewModel.policy else { return }
        Task {
            let adminSettings: AdminNotificationFilterSettings? = await {
                guard let user = AuthenticationServiceProvider.shared.currentActiveUser.value, let role = user.cachedAccount?.role else { return nil }
                let permissions = role.rolePermissions()
                let hasAdminPermissions = permissions.contains(.administrator) || permissions.contains(.manageReports) || permissions.contains(.manageUsers)
                guard hasAdminPermissions else { return nil }
                if let existingPreferences = await BodegaPersistence.Notifications.currentPreferences(for: user.authentication) {
                    return existingPreferences
                } else {
                    return AdminNotificationFilterSettings(forReports: .accept, forSignups: .accept)
                }
            }()
            
            let policyViewModel = await NotificationPolicyViewModel(
                NotificationFilterSettings(
                    forNotFollowing: policy.forNotFollowing,
                    forNotFollowers: policy.forNotFollowers,
                    forNewAccounts: policy.forNewAccounts,
                    forPrivateMentions: policy.forPrivateMentions,
                    forLimitedAccounts: policy.forLimitedAccounts
                ),
                adminSettings: adminSettings
            )
            let navigator = tabViewRouter.navigationRouter(forTab: .notifications)
            policyViewModel.dismissView = { [weak navigator] in
                navigator?.dismissCurrentModal()
            }
            policyViewModel.didDismissView = { [weak tabViewRouter] _ in
                tabViewRouter?.fetchFilteredNotificationsPolicy(andReloadFeed: true)
            }
            
            navigator.presentSheet(.notificationPolicy(policyViewModel), afterDeconflictionDelay: false)
        }
    }
    
    @ViewBuilder func timelineNavigationStack(forTab tab: MastodonTabViewRouter.MastodonTab, includeTimelineSwitcherMenu: Bool) -> some View {
        @Bindable var navigationStackNavigator = tabViewRouter.navigationRouter(forTab: tab)
        if let timelineModel = timelineViewModel(forTab: tab) {
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                TimelineListView()
                    .timelineEnvironment(timelineModel: timelineModel, contentConcealModel: .alwaysShow, filter: timelineModel.timelineQueryFilter, asyncRefreshModel: timelineModel.asyncRefreshViewModel)
                    .navigationTitle(includeTimelineSwitcherMenu ? currentHomeFeedName ?? "" : "")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        if tab == .home, let authBox = authenticationObserver.currentActiveUser {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    showAccountSwitcher = true
                                } label: {
                                    avatarIconRenderer.prerenderedAccountAvatar(authBox.globallyUniqueUserIdentifier, style: .circular)
                                }
                                .popover(isPresented: $showAccountSwitcher) {
                                    accountSwitcherView()
                                }
                            }
                            .sharedBackgroundVisibilityHidden()
                            
                            if sizeClass != .compact {
                                ToolbarItem(placement: .topBarTrailing) {
                                    modalComposeButton(forTab: tab)
                                }
                                .sharedBackgroundVisibilityHidden()
                            }
                            
                            if includeTimelineSwitcherMenu {
                                ToolbarTitleMenu() {
                                    homeTimelineFeedPickerContents
                                }
                                
                            }
                        }
                    }
                    .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                        navigationStackNavigator.destinationView(destination, sceneCoordinator: sceneCoordinator)
                    }
            }
            .environment(navigationStackNavigator)
            .overlay(alignment: .bottomTrailing) {
                if sizeClass == .compact {
                    modalComposeButton(forTab: tab)
                }
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder var homeTimelineFeedPickerContents: some View {
        let homeTabNavigator = tabViewRouter.navigationRouter(forTab: .home)
        Button(L10n.Scene.HomeTimeline.TimelineMenu.following) {
            tabViewRouter.homeTimelineModel?.setTimeline(.homeTimeline, navigator: homeTabNavigator)
        }
        if tabViewRouter.isLocalTimelineAvailable {
            Button(L10n.Scene.HomeTimeline.TimelineMenu.localCommunity) {
                tabViewRouter.homeTimelineModel?.setTimeline(.local, navigator: homeTabNavigator)
            }
        }
        if !tabViewRouter.lists.isEmpty {
            Menu(L10n.Scene.HomeTimeline.TimelineMenu.Lists.title) {
                ForEach(tabViewRouter.lists, id: \.self.id) { list in
                    Button(list.title) {
                        tabViewRouter.homeTimelineModel?.setTimeline(.list(list.id), navigator: homeTabNavigator)
                    }
                }
            }
        }
        if !tabViewRouter.followedHashtags.isEmpty {
            Menu(L10n.Scene.HomeTimeline.TimelineMenu.Hashtags.title) {
                ForEach(tabViewRouter.followedHashtags, id: \.self.name) { hashtag in
                    Button("#\(hashtag.name)") {
                        tabViewRouter.homeTimelineModel?.setTimeline(.hashtag(hashtag, includeHeader: false), navigator: homeTabNavigator)
                    }
                }
            }
        }
    }
    
    var currentHomeFeedName: String? {
        guard let timeline = tabViewRouter.homeTimelineModel?.timeline else { return nil }
        switch timeline {
        case .homeTimeline:
            return L10n.Scene.HomeTimeline.TimelineMenu.following
        case .local:
            return L10n.Scene.HomeTimeline.TimelineMenu.localCommunity
        case .list(let listID):
            return tabViewRouter.lists.first(where: { $0.id == listID })?.title
        case .hashtag(let hashtag, _):
            return "#\(hashtag.name)"

        default:
            return nil
        }
    }
}

@MainActor
@Observable class AvatarIconRenderer {
    public static let shared = AvatarIconRenderer()
    var displayScale: CGFloat = 1 {
        didSet {
            if oldValue != displayScale {
                accountAvatarIconsRendered.removeAll(keepingCapacity: true)
                currentRender?.1.cancel()
                currentRender = nil
            }
        }
    }
    public private(set) var accountAvatarIconsRendered = [ String : Image ]()
    public private(set) var accountAvatarsCircularCropped = [ String : Image ]()
    
    private var accountAvatarImages = [ String : UIImage ]()
    private var renderQueue = [String]()
    private var currentRender: (String, Task<Void, Never>)?
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        loadAccountAvatars() // in case any are already available
        NotificationCenter.default.addObserver(  // attempt to load avatars again when users are fetched asynchronously (usually only the current active user is available immediately)
            forName: .userFetched,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.loadAccountAvatars()
            }
        }

        AuthenticationServiceProvider.shared.$mastodonAuthenticationBoxes // and reload again whenever the set of users changes
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.loadAccountAvatars()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func loadAccountAvatars() {
        for authBox in AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes {
            let accountGUID = authBox.globallyUniqueUserIdentifier
            guard accountAvatarImages[accountGUID] == nil else { continue }
            guard let avatarURL = authBox.cachedAccount?.avatarImageURL() else {
                continue
            }
            SDWebImageManager.shared.loadImage(
                with: avatarURL,
                progress: nil) { [weak self] image, _, _, _, _, _ in
                    guard let self, let image else { return }
                    self.accountAvatarImages[accountGUID] = image
                    self.enqueueRender(accountGUID)
                }
        }
    }
    
    func prerenderedAccountAvatar(_ accountGUID: String, style: AvatarView.AvatarStyle) -> Image? {
        let prerendered = {
            switch style {
            case .roundedRect:
                self.accountAvatarIconsRendered[accountGUID]
            case .circular:
                self.accountAvatarsCircularCropped[accountGUID]
            }
        }()
        if prerendered != nil {
            return prerendered
        } else {
            enqueueRender(accountGUID)
        }
        return nil
    }

    private func enqueueRender(_ accountGUID: String) {
        guard !renderQueue.contains(accountGUID), currentRender?.0 != accountGUID else { return }
        renderQueue.append(accountGUID)
        doNextRender()
    }
    
    func baseImage(_ accountGUID: String) -> Image? {
        if let image = accountAvatarImages[accountGUID] {
            return Image(uiImage: image)
        }
        return nil
    }
    
    private func doNextRender() {
        if currentRender == nil, !renderQueue.isEmpty {
            let nextRenderGUID = renderQueue.removeFirst()
            currentRender = (nextRenderGUID, Task {
                defer {
                    currentRender = nil
                    doNextRender()
                }
                guard !Task.isCancelled else { return }
                guard let image = accountAvatarImages[nextRenderGUID] else { return }
                
                let roundedRectAvatarView = AvatarView(style: .roundedRect, size: .small, borderStyle: .separator, avatarSource: .local(Image(uiImage: image)))
                let rectRenderer = ImageRenderer(content: roundedRectAvatarView)
                rectRenderer.scale = displayScale
                guard let rendered = rectRenderer.uiImage else { return }
                accountAvatarIconsRendered[nextRenderGUID] = Image(uiImage: rendered)
                
                let circularAvatarView = AvatarView(style: .circular, size: .small, borderStyle: .separator, avatarSource: .local(Image(uiImage: image)))
                let circRenderer = ImageRenderer(content: circularAvatarView)
                circRenderer.scale = displayScale
                guard let rendered = circRenderer.uiImage else { return }
                accountAvatarsCircularCropped[nextRenderGUID] = Image(uiImage: rendered)
            })
        }
    }
}

extension MastodonTabViewRouter.MastodonTab {
    var title: String {
        switch self {
        case .home:
            L10n.Common.Controls.Tabs.home
        case .explore:
            L10n.Common.Controls.Tabs.A11Y.explore
        case .notifications:
            L10n.Common.Controls.Tabs.notifications
        case .profile:
            L10n.Common.Controls.Tabs.profile
        case .localFeed:
            L10n.Scene.HomeTimeline.TimelineMenu.localCommunity
        case .lists:
            L10n.Scene.HomeTimeline.TimelineMenu.Lists.title
        case .hashtags:
            L10n.Scene.HomeTimeline.TimelineMenu.Hashtags.title
        case .list(let list):
            list.title
        case .hashtag(let hashtag):
            hashtag.name
        }
    }
    
    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .explore:
            "binoculars"
        case .notifications:
            "bell"
        case .profile:
            "person"
        case .localFeed:
            "building.2"
        case .lists, .list:
            "list.star"
        case .hashtags, .hashtag:
            "number"
        }
    }
    
    var customizationBehavior: TabCustomizationBehavior {
        switch self {
        case .home, .explore, .notifications, .profile, .lists, .hashtags:
                .disabled
        case .localFeed, .list, .hashtag:
                .automatic
        }
    }
    
    var defaultTabBarVisibility: Visibility {
        switch self {
        case .home, .explore, .notifications, .profile:
                .visible
        case .localFeed, .lists, .hashtags, .list, .hashtag:
                .hidden
        }
    }
}

@MainActor
@Observable class AuthenticationObserver {
    static let shared = AuthenticationObserver()
    
    private(set) var currentActiveUser: MastodonAuthenticationBox?
    private(set) var allLoggedInUsers = [MastodonAuthenticationBox]()
    private var subscriptions = Set<AnyCancellable>()
    
    private init() {
        let authenticationServiceProvider = AuthenticationServiceProvider.shared
        currentActiveUser = authenticationServiceProvider.currentActiveUser.value
        allLoggedInUsers = authenticationServiceProvider.mastodonAuthenticationBoxes
        authenticationServiceProvider.currentActiveUser.assign(to: \.currentActiveUser, on: self).store(in: &subscriptions)
        authenticationServiceProvider.$mastodonAuthenticationBoxes.assign(to: \.allLoggedInUsers, on: self).store(in: &subscriptions)
    }
}

struct LegacyNavigationViewControllerWrapper: UIViewControllerRepresentable {
    
    let startingRootViewController: UIViewController
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let navController = UINavigationController(rootViewController: startingRootViewController)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // nothing to do?
    }
}

struct LegacyComposeViewControllerWrapper: UIViewControllerRepresentable {
    let authBox: MastodonAuthenticationBox
    let composeViewModel: ComposeViewModel?
    let composeContentViewModel: ComposeContentViewModel?
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let viewModel = composeViewModel ?? ComposeViewModel(authenticationBox: authBox, composeContext: .composeStatus(quoting: nil), destination: .topLevel)
        let composer = ComposeViewController(viewModel: viewModel, draftContentModel: composeContentViewModel)
        let navigationWrapper = UINavigationController(rootViewController: composer)
        return navigationWrapper
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // nothing to do?
    }
}

struct LegacyReportFlowViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ReportViewModel
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let rootVC = ReportViewController(viewModel: viewModel)
        let navigationWrapper = UINavigationController(rootViewController: rootVC)
        return navigationWrapper
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // nothing to do?
    }
}

struct LegacyWelcomeFlowWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let rootVC = WelcomeViewController()
        let navigationWrapper = UINavigationController(rootViewController: rootVC)
        return navigationWrapper
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // nothing to do?
    }
}

struct LegacyViewControllerWrapper: UIViewControllerRepresentable {
    let sceneCoordinator: SceneCoordinator
    let scene: SceneCoordinator.Scene
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = sceneCoordinator.get(scene: scene)
        return vc ?? UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // nothing to do?
    }
}
