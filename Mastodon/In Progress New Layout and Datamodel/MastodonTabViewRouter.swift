// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonUI
import MastodonSDK
import Combine

@MainActor
@Observable class MastodonTabViewRouter {
    
    public private(set) static var current = MastodonTabViewRouter(authenticatedUser: AuthenticationServiceProvider.shared.currentActiveUser.value)
    
    let userGUID: String
    private let authenticationBox: MastodonAuthenticationBox?
    public var homeTimelineModel: TimelineListViewModel?
    public var notificationsTimelineModelEverything: TimelineListViewModel?
    public var notificationsTimelineModelMentions: TimelineListViewModel?
    public var selectedNotificationsTimeline: NotificationsScope = .everything
    public var searchModel: SearchViewModel
    public var discoveryModel: DiscoveryFeedsViewModel
    public var customTimelineModels = [ MastodonTab : TimelineListViewModel]()
    
    public var isLocalTimelineAvailable: Bool = false
    public var isHomeTimelineFilterAvailable: Bool = false
    public var lists: [Mastodon.Entity.List] = []
    public var followedHashtags: [Mastodon.Entity.Tag] = []
    
    private var _combineSubscriptions = Set<AnyCancellable>()
    
    @ObservationIgnored private var _myProfileViewModel: ProfileViewModel?
    
    public var myProfileViewModel: ProfileViewModel? {
        if let _myProfileViewModel { return _myProfileViewModel }
        guard let authenticationBox, let account = authenticationBox.cachedAccount else { return nil }
        let model = ProfileViewModel()
        model.set(account: MastodonAccount.fromEntity(account, authenticatedDomain: authenticationBox.domain), relationship: .isMe, navigator: navigationRouter(forTab: .profile))
        _myProfileViewModel = model
        return model
    }
    
    private var _currentDraftContentViewModel: ComposeContentViewModel?
    
    public func currentDraftContentViewModel(authBox: MastodonAuthenticationBox) -> ComposeContentViewModel? {
        if let _currentDraftContentViewModel, _currentDraftContentViewModel.authenticationBox == authBox {
            return _currentDraftContentViewModel
        } else {
            _currentDraftContentViewModel = ComposeContentViewModel(authenticationBox: authBox, composeContext: .composeStatus(quoting: nil), destination: .topLevel, initialContent: "", requestConfirmToDismiss: false) { [weak self] outcome in
                switch outcome {
                case .success:
                    self?.clearDraftContentViewModel()
                case .failure, .cancelled:
                    break
                }
            }
            return _currentDraftContentViewModel
        }
    }
    
    public func clearDraftContentViewModel() {
        _currentDraftContentViewModel = nil
    }
    
    public static func changeAuthenticatedUser(_ newUser: MastodonAuthenticationBox?) -> MastodonTabViewRouter {
        let updated = MastodonTabViewRouter(authenticatedUser: newUser)
        current = updated
        return updated
    }
    
    private init(authenticatedUser: MastodonAuthenticationBox?) {
        userGUID = authenticatedUser?.globallyUniqueUserIdentifier ?? "NONE"
        authenticationBox = authenticatedUser
        searchModel = SearchViewModel(authenticationBox: authenticatedUser)
        discoveryModel = DiscoveryFeedsViewModel()
        if let authenticatedUser {
            updateFeatureAvailability(authenticatedUser)
            updateLists(authenticatedUser)
            updateFollowedHashtags(authenticatedUser)
            
            AuthenticationServiceProvider.shared.updateActiveUserAccountPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
                self?.updateLists(authenticatedUser)
                self?.updateFollowedHashtags(authenticatedUser)
            }.store(in: &_combineSubscriptions)
            
            AuthenticationServiceProvider.shared.instanceConfigurationUpdates
                .receive(on: DispatchQueue.main)
                .sink{ [weak self] updatedDomain in
                    guard let self, authenticatedUser.domain == updatedDomain else { return }
                    self.updateFeatureAvailability(authenticatedUser)
                }.store(in: &_combineSubscriptions)
            
            NotificationCenter.default.publisher(for: .followedTagsDidChange)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateFollowedHashtags(authenticatedUser)
                }.store(in: &_combineSubscriptions)
            
            NotificationCenter.default.publisher(for: .listsDidChange)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateLists(authenticatedUser)
                }.store(in: &_combineSubscriptions)
        }
    }
    
    private func updateFeatureAvailability(_ authenticatedUser: MastodonAuthenticationBox) {
        isLocalTimelineAvailable = authenticatedUser.authentication.instanceConfiguration?.isAvailable(.localTimeline) ?? true
        isHomeTimelineFilterAvailable = authenticatedUser.authentication.instanceConfiguration?.isAvailable(.homeTimelineFilters) ?? false
    }
    
    private var isUpdatingLists = false
    private var needsAnotherUpdateLists = false
    private func updateLists(_ authenticatedUser: MastodonAuthenticationBox) {
        guard !isUpdatingLists else { needsAnotherUpdateLists = true; return }
        isUpdatingLists = true
        needsAnotherUpdateLists = false
        Task {
            defer {
                isUpdatingLists = false
                if needsAnotherUpdateLists {
                    updateLists(authenticatedUser)
                }
            }
            do {
                lists = try await APIService.shared.getLists(authenticationBox: authenticatedUser).value
            } catch {
                navigationRouter(forTab: .home).didReceiveError(error)
            }
        }
    }
    
    private var isUpdatingHashtags = false
    private var needsAnotherUpdateHashtags = false
    private func updateFollowedHashtags(_ authenticatedUser: MastodonAuthenticationBox) {
        guard !isUpdatingHashtags else { needsAnotherUpdateHashtags = true; return }
        isUpdatingHashtags = true
        needsAnotherUpdateHashtags = false
        Task {
            defer {
                isUpdatingHashtags = false
                if needsAnotherUpdateHashtags {
                    updateFollowedHashtags(authenticatedUser)
                }
            }
            do {
                followedHashtags = try await APIService.shared.getFollowedTags(query: .init(limit: nil), authenticationBox: authenticatedUser).value
            } catch {
                navigationRouter(forTab: .home).didReceiveError(error)
            }
        }
    }
        
    enum MastodonTab: Identifiable, Hashable {
        static func == (lhs: MastodonTabViewRouter.MastodonTab, rhs: MastodonTabViewRouter.MastodonTab) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        case home
        case explore
        case notifications
        case profile
        case lists
        case hashtags
        case localFeed
        case list(Mastodon.Entity.List)
        case hashtag(Mastodon.Entity.Tag)
        
        var id: String {
            switch self {
            case .home: "home"
            case .explore: "explore"
            case .notifications: "notifications"
            case .profile: "profile"
            case .hashtags: "hashtags"
            case .lists: "lists"
            case .localFeed: "localFeed"
            case .list(let list):
                "list-\(list.id)"
            case .hashtag(let tag):
                "hashtag-\(tag.name)"
            }
        }
        
        var homeTabAlternateTimeline: MastodonTimelineType? {
            switch self {
            case .home:
                return nil
            case .localFeed:
                return .local
            case .list(let list):
                return .list(list.id)
            case .hashtag(let hashtag):
                return .hashtag(hashtag, includeHeader: false)
            case .explore, .notifications, .profile, .lists, .hashtags:
                return nil
            }
        }
    }
    
    var selectedTab: MastodonTab = .home
    
    private var navigationRouters = [ MastodonTab : MastodonNavigationRouter]()
    
    private(set) var currentTabBarPlacement: TabBarPlacement?
    
    var tabs: [MastodonTab] {
        return [.home, isLocalTimelineAvailable ? .localFeed : nil, .explore, .notifications, .profile, .lists, .hashtags]
            .compactMap { $0 }
    }
    
    public func show(_ destination: MastodonNavigationDestination, in tab: MastodonTab) {
        if selectedTab != tab {
            selectedTab = tab
        }
        navigationRouter(forTab: tab).push(destination)
    }
    
    public func navigationRouter(forTab tab: MastodonTab) -> MastodonNavigationRouter {
        if let existing = navigationRouters[tab] {
            return existing
        }
        let freshRouter = MastodonNavigationRouter(authenticationBox: authenticationBox)
        navigationRouters[tab] = freshRouter
        return freshRouter
    }
    
    public func navigationRouterForCurrentTab() -> MastodonNavigationRouter {
        return navigationRouter(forTab: selectedTab)
    }
   
    func openSearch(_ searchString: String?) {
        guard AuthenticationObserver.shared.currentActiveUser != nil else { return }
        if let searchString {
            searchModel.searchText = searchString
        }
        searchModel.isSearchActive = true
        let searchTabRouter = navigationRouter(forTab: .explore)
        searchTabRouter.navigationPath.removeAll()
        selectedTab = .explore
    }
    
    func openExplore(_ discoveryType: DiscoveryType) {
        guard AuthenticationObserver.shared.currentActiveUser != nil else { return }
        searchModel.searchText = ""
        searchModel.isSearchActive = false
        
        discoveryModel.selectedViewType = discoveryType
        let discoveryTabRouter = navigationRouter(forTab: .explore)
        discoveryTabRouter.navigationPath.removeAll()
        selectedTab = .explore
    }
    
    func fetchFilteredNotificationsPolicy(andReloadFeed reload: Bool) {
        guard
            let authBox = AuthenticationObserver.shared.currentActiveUser
        else { return }
        Task {
            let policy = try? await APIService.shared.notificationPolicy(
                authenticationBox: authBox)
            notificationsTimelineModelEverything?.updateFilteredNotificationsPolicy(policy?.value, andReloadFeed: reload)
            notificationsTimelineModelMentions?.updateFilteredNotificationsPolicy(policy?.value, andReloadFeed: reload)
        }
    }
    
    func didObserveTabBarPlacement(_ placement: TabBarPlacement?, inTab tab: MastodonTab) {
        guard tab == selectedTab else { return } // unselected tabs still report values, but they are often incorrect
        guard placement != currentTabBarPlacement else { return }
        currentTabBarPlacement = placement
        if placement.isSidebarAvailable {
            moveHomeFeedToSidebar()
        } else {
            moveSidebarFeedToHome()
        }
    }
    
    private func moveHomeFeedToSidebar() {
        // when a sidebar is available, the home tab doesn't show the feed switcher, so the extra feeds have to be shown in the sidebar as their own tabs
        guard let homeTimelineModel, homeTimelineModel.timeline != .homeTimeline else { return }
        if selectedTab == .home, let feedTab = sidebarTab(showing: homeTimelineModel.timeline) {
            selectedTab = feedTab
        }
        let navigator = navigationRouter(forTab: .home)
        navigator.popToRoot()
        homeTimelineModel.setTimeline(.homeTimeline, navigator: navigator)
    }
    
    private func sidebarTab(showing timeline: MastodonTimelineType) -> MastodonTab? {
        switch timeline {
        case .local:
            return isLocalTimelineAvailable ? .localFeed : nil
        case .list(let listID):
            return lists.first(where: { $0.id == listID }).map { .list($0) }
        case .hashtag(let tag, _):
            return followedHashtags.first(where: { $0.name == tag.name }).map { .hashtag($0) }
        default:
            return nil
        }
    }
    
    private func moveSidebarFeedToHome() {
        // all feeds have their own tabs in the sidebar (or when the sidebar is available via the top bar), but when the tab bar is the bottom bar, those feeds are all shown in the home tab and accessed via the switcher menu.
        guard let timeline = selectedTab.homeTabAlternateTimeline else { return }
        let navigator = navigationRouter(forTab: .home)
        navigator.popToRoot() // TODO: hold onto the navigation path per timeline, so that context is not lost?
        timelineViewModel(forTab: .home)?.setTimeline(timeline, navigator: navigator)
        selectedTab = .home
    }
    
    // MARK - Overlays
    var activeOverlayID: UUID? = nil
    var activeOverlay: MastodonFadeInOverlay? = nil
    func setActiveOverlay(_ overlay: MastodonFadeInOverlay?, animated: Bool) {
        activeOverlayID = overlay == nil ? nil : UUID()
        if animated {
            withAnimation { activeOverlay = overlay }
        } else {
            activeOverlay = overlay
        }
    }
    
    func timelineViewModel(forTab tab: MastodonTabViewRouter.MastodonTab) -> TimelineListViewModel? {
        switch tab {
        case .home:
            if let model = homeTimelineModel {
                return model
            } else {
                let model = TimelineListViewModel(timeline: .homeTimeline, navigator: navigationRouter(forTab: .home), asyncRefreshViewModel: AsyncRefreshViewModel())
                homeTimelineModel = model
                return model
            }
            
        case .localFeed, .list, .hashtag:
            if let model = customTimelineModels[tab] {
                return model
            } else if let timeline = tab.homeTabAlternateTimeline {
                let model = TimelineListViewModel(timeline: timeline, navigator: navigationRouter(forTab: tab), asyncRefreshViewModel: AsyncRefreshViewModel())
                customTimelineModels[tab] = model
                return model
            } else {
                return nil
            }
            
        default:
            return nil
        }
    }
}

extension Optional where Wrapped == TabBarPlacement {
    var isSidebarAvailable: Bool {
        switch self {
        case .sidebar, .topBar:
            return true
        case .bottomBar:
            return false
        case .ornament, .pageIndicator:
            return false
        default:
            return false
        }
    }
}

struct TabBarPlacementReporter: ViewModifier {
    let reportingFromTab: MastodonTabViewRouter.MastodonTab
    @Environment(MastodonTabViewRouter.self) private var tabViewRouter
    @Environment(\.tabBarPlacement) private var tabBarPlacement
    
    func body(content: Content) -> some View {
        content
            .onChange(of: tabBarPlacement, initial: true) { _, placement in
                tabViewRouter.didObserveTabBarPlacement(placement, inTab: reportingFromTab)
            }
    }
}

struct NavigationTitle: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        content.navigationTitle(title)
    }
}
