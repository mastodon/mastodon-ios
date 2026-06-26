// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonUI
import SDWebImageSwiftUI
import MastodonAsset
import Combine

extension EnvironmentValues {
    @Entry var sceneCoordinator: SceneCoordinator? = nil
}

struct MastodonMainTabView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.displayScale) private var displayScale
    @Environment(\.sceneCoordinator) private var sceneCoordinator
    
    @State private var authenticationObserver = AuthenticationObserver.shared
    @State private var navigator = MastodonTabViewRouter.current
    @State private var avatarIconRenderer = AvatarIconRenderer.shared
    @State private var showAccountSwitcher = false
    @State private var isSwitchingAccounts = false
   
    
    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            ForEach(navigator.tabs(forSizeClass: sizeClass), id: \.self) { tab in
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
                    // Profile is a special case because when sidebar is available we are showing the current profile as a navigation tab and any other logged-in accounts as actions, plus an add additional account action, but when sidebar is not available (.compact width), we only want to show the profile icon
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
                        }
                        
                    case .compact, .none:
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
                        view(forTab: tab)
                    }
                }
            }
        }
        .environment(authenticationObserver)
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: authenticationObserver.currentActiveUser, initial: true) { _, newValue in
            guard MastodonTabViewRouter.current.userGUID != newValue?.globallyUniqueUserIdentifier else { return }
            let newRouter = MastodonTabViewRouter.changeAuthenticatedUser(newValue)
            navigator = newRouter
        }
        .onChange(of: displayScale, initial: true) { _, newValue in
            AvatarIconRenderer.shared.displayScale = newValue
        }
        .sheet(item: $navigator.presentedModal) { presentedItem in
            switch presentedItem {
            case .timeline:
                Text("Timeline not implemented as modal presentation")
            case .profile:
                Text("Profile not implemented as modal presentation")
            case .editProfile:
                Text("Edit Profile not implemented as modal presentation")
            case .editProfileNavigation:
                Text("Edit Profile Navigation not implemented as modal presentation")
            case .share:
                Text("Share not implemented as modal presentation")
            case .legacy(let scene, _):
                if let vc = sceneCoordinator?.get(scene: scene) {
                    if vc is UINavigationController, let root = vc.topMost {
                        LegacyNavigationViewControllerWrapper(startingRootViewController: root)
                    } else {
                        LegacyNavigationViewControllerWrapper(startingRootViewController: vc)
                    }
                } else {
                    Text("\(scene) not implemented as modal presentation")
                }
            }
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
        case .home, .explore, .compose, .notifications, .profile, .list, .hashtag:
            return nil
        case .lists:
            return [.list("alist"), .list("blist")]
        case .hashtags:
            return [.hashtag("ahashtag"), .hashtag("bhashtag")]
        }
    }
    
    @ViewBuilder private func view(forTab tab: MastodonTabViewRouter.MastodonTab) -> some View {
        switch tab {
        case .home:
            @Bindable var navigationStackNavigator = navigator.navigationRouter(forTab: tab)
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                let timelineModel = homeTimelineViewModel()
                TimelineListView()
                    .timelineEnvironment(timelineModel: timelineModel, contentConcealModel: .alwaysShow, filter: timelineModel.timelineQueryFilter, asyncRefreshModel: timelineModel.asyncRefreshViewModel)
                    .toolbar {
                        if let accountGUID = AuthenticationServiceProvider.shared.currentActiveUser.value?.globallyUniqueUserIdentifier {
                            if #available(iOS 26.0, *) {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        showAccountSwitcher = true
                                    } label: {
                                        avatarIconRenderer.prerenderedAccountAvatar(accountGUID, style: .circular)
                                    }
                                    .popover(isPresented: $showAccountSwitcher) {
                                        accountSwitcherView()
                                    }
                                }
                                .sharedBackgroundVisibility(.hidden)
                            } else {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        showAccountSwitcher = true
                                    } label: {
                                        avatarIconRenderer.prerenderedAccountAvatar(accountGUID, style: .circular)
                                    }
                                    .popover(isPresented: $showAccountSwitcher) {
                                        accountSwitcherView()
                                    }
                                }
                            }
                        }
                    }
                    .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                        navigationStackNavigator.destinationView(destination, sceneCoordinator: sceneCoordinator)
                    }
            }
            .environment(navigationStackNavigator)
            .environment(NestedScrollInteractionViewModel())
            
        case .explore:
            @Bindable var navigationStackNavigator = navigator.navigationRouter(forTab: .explore)
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                ExploreRootView(sceneCoordinator: sceneCoordinator)
            }
            .environment(navigationStackNavigator)
            .environment(navigator.searchModel)

        case .compose:
            if let authBox = authenticationObserver.currentActiveUser {
                LegacyComposeViewControllerWrapper(authBox: authBox)
                    .frame(maxWidth: 680)
                    .frame(maxHeight: 700)
                // probably needs an id to regenerate when you publish a post
            } else {
                Asset.Colors.FigmaToken.bgSoftest.swiftUIColor
            }
            
        case .notifications:
            @Bindable var navigationStackNavigator = navigator.navigationRouter(forTab: tab)
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                let timelineModel = notificationsTimelineViewModel(scope: navigator.selectedNotificationsTimeline)
                TimelineListView()
                    .timelineEnvironment(timelineModel: timelineModel, contentConcealModel: .alwaysShow, filter: timelineModel.timelineQueryFilter, asyncRefreshModel: timelineModel.asyncRefreshViewModel)
                    .toolbar {
                            // picker as the center item
                            ToolbarItem(placement: .title) {
                                Picker("Scope", selection: $navigator.selectedNotificationsTimeline) {
                                    Text("Everything")
                                        .tag(NotificationsScope.everything)
                                    Text("Mentions")
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
            .environment(NestedScrollInteractionViewModel())
        case .profile:
            @Bindable var navigationStackNavigator = navigator.navigationRouter(forTab: tab)
            let profileModel = profileViewModel()
            NavigationStack(path: $navigationStackNavigator.navigationPath) {
                ProfileView(wrapInSwiftUINavigationStack: false)
                    .profileEnvironment(profileModel, nestedScroll: NestedScrollInteractionViewModel())
            }
            .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                navigationStackNavigator.destinationView(destination, sceneCoordinator: sceneCoordinator)
            }
            .environment(navigationStackNavigator)
        default:
            Text(tab.title)
                .font(.largeTitle)
        }
    }
    
    @ViewBuilder private var settingsButton: some View {
        Button {
            let needsDismiss = showAccountSwitcher || self.navigator.presentedModal != nil
            if needsDismiss {
                showAccountSwitcher = false
                self.navigator.dismissCurrentModal()
            }
            self.navigator.presentModal(.legacy(scene: .settings, transition: .modal(animated: true, completion: nil)), afterDeconflictionDelay: needsDismiss)
        } label: {
            Label {
                Text("Settings")
            } icon: {
                Image(systemName: "gear")
            }
        }
    }
    
    @ViewBuilder private func alternateAccountButtons() -> some View {
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
                .padding()
            }
        }
        Button {
            let needsDismissCurrent = showAccountSwitcher
            if needsDismissCurrent {
                // must dismiss or the new modal presentation will not happen
                showAccountSwitcher = false
            }
            navigator.presentModal(.legacy(scene: .welcome, transition: .modal(animated: true, completion: nil)), afterDeconflictionDelay: needsDismissCurrent)
        } label: {
            Label {
                Text("Add account")
            } icon: {
                Image(systemName: "plus")
            }
            .padding()
        }
    }
    
    @ViewBuilder private func accountSwitcherView() -> some View {
        LazyVStack(alignment: .leading) {
            if let currentAuthBox = AuthenticationServiceProvider.shared.currentActiveUser.value, let currentAuthAccount = currentAuthBox.cachedAccount, let icon = avatarIconRenderer.prerenderedAccountAvatar(currentAuthBox.globallyUniqueUserIdentifier, style: .circular) {
                Button {
                    navigator.selectedTab = .profile
                } label: {
                    Label {
                        let handle = currentAuthAccount.acctWithDomain
                        Text("@\(handle)")
                    } icon: {
                        icon
                    }
                }
                .padding()
            }
            settingsButton
                .padding(.horizontal)
            Divider()
            alternateAccountButtons()
        }
        .padding()
    }

    private func homeTimelineViewModel() -> TimelineListViewModel {
        if let model = navigator.homeTimelineModel {
            return model
        } else {
            let model = TimelineListViewModel(timeline: .homeTimeline, navigator: navigator.navigationRouter(forTab: .home), asyncRefreshViewModel: AsyncRefreshViewModel())
            navigator.homeTimelineModel = model
            return model
        }
    }
    
    func profileViewModel() -> ProfileViewModel {
        if let model = navigator.profileModel {
            return model
        } else {
            let model = ProfileViewModel()
            guard let authBox = authenticationObserver.currentActiveUser, let account = authBox.cachedAccount else { return model }
            model.set(account: MastodonAccount.fromEntity(account, authenticatedDomain: authBox.domain), relationship: .isMe, navigator: navigator.navigationRouter(forTab: .profile))
            navigator.profileModel = model
            return model
        }
    }
    
    private func notificationsTimelineViewModel(scope: NotificationsScope) -> TimelineListViewModel {
        func newModel() -> TimelineListViewModel {
            let new = TimelineListViewModel(timeline: .notifications(scope: scope), navigator: navigator.navigationRouter(forTab: .notifications), asyncRefreshViewModel: AsyncRefreshViewModel())
            navigator.fetchFilteredNotificationsPolicy(andReloadFeed: false)
            return new
        }
        switch scope {
        case .everything:
            if let model = navigator.notificationsTimelineModelEverything {
                return model
            }
            let new = newModel()
            navigator.notificationsTimelineModelEverything = new
            return new
        case .mentions:
            if let model = navigator.notificationsTimelineModelMentions {
                return model
            }
            let new = newModel()
            navigator.notificationsTimelineModelMentions = new
            return new
        case .fromRequest:
            assertionFailure()
            return newModel()
        }
    }
    
    private func switchTo(_ authBox: MastodonAuthenticationBox) {
        isSwitchingAccounts = true
        let needsDismiss = navigator.presentedModal != nil || showAccountSwitcher
        if needsDismiss {
            navigator.dismissCurrentModal()
            showAccountSwitcher = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) { // this delay gives the modals time to dismiss, making the transition feel less abrupt
            AuthenticationServiceProvider.shared.activateAuthentication(authBox)
            self.isSwitchingAccounts = false
        }
    }
    
    private func showNotificationPolicySettings() {
        guard let policy = notificationsTimelineViewModel(scope: navigator.selectedNotificationsTimeline).filteredNotificationsViewModel.policy else { return }
        Task {
            let adminSettings: AdminNotificationFilterSettings? = await {
                guard let user = AuthenticationServiceProvider.shared.currentActiveUser.value, let role = user.cachedAccount?.role else { print("no role"); return nil }
                let permissions = role.rolePermissions()
                let hasAdminPermissions = permissions.contains(.administrator) || permissions.contains(.manageReports) || permissions.contains(.manageUsers)
                guard hasAdminPermissions else { print("no permissions"); return nil }
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
            
            guard let policyViewController = self.sceneCoordinator?.present(scene: .notificationPolicy(viewModel: policyViewModel), transition: .formSheet(policyViewModel.adminFilterSettings != nil ? [.large()] : nil)) as? NotificationPolicyViewController else { return }
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
                
                let roundedRectAvatarView = AvatarView(style: .roundedRect, size: .small, borderStyle: .separator, avatarSource: .local(Image(uiImage: image)), goToProfile: {})
                let rectRenderer = ImageRenderer(content: roundedRectAvatarView)
                rectRenderer.scale = displayScale
                guard let rendered = rectRenderer.uiImage else { return }
                accountAvatarIconsRendered[nextRenderGUID] = Image(uiImage: rendered)
                
                let circularAvatarView = AvatarView(style: .circular, size: .small, borderStyle: .separator, avatarSource: .local(Image(uiImage: image)), goToProfile: {})
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


struct LegacySearchViewControllerWrapper: UIViewControllerRepresentable {
    let authBox: MastodonAuthenticationBox?

    func makeUIViewController(context: Context) -> UINavigationController {
        let searchViewController = SearchViewController()
        searchViewController.viewModel = SearchViewModel(authenticationBox: authBox)
        return AdaptiveStatusBarStyleNavigationController(rootViewController: searchViewController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // nothing to do?
    }
}


struct LegacyComposeViewControllerWrapper: UIViewControllerRepresentable {
    let authBox: MastodonAuthenticationBox
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let viewModel = ComposeViewModel(authenticationBox: authBox, composeContext: .composeStatus(quoting: nil), destination: .topLevel)
            let composer = ComposeViewController(viewModel: viewModel)
        let navigationWrapper = UINavigationController(rootViewController: composer)
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
