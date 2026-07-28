// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonUI

@MainActor
@Observable class MastodonTabViewRouter {
    
    public private(set) static var current = MastodonTabViewRouter(authenticatedUser: nil)
    
    let userGUID: String
    public var homeTimelineModel: TimelineListViewModel?
    public var notificationsTimelineModelEverything: TimelineListViewModel?
    public var notificationsTimelineModelMentions: TimelineListViewModel?
    public var profileModel: ProfileViewModel?
    public var selectedNotificationsTimeline: NotificationsScope = .everything
    public var searchModel: SearchModel
    public var discoveryModel: DiscoveryFeedsViewModel
    private var _currentDraftContentViewModel: ComposeContentViewModel?
    
    public func currentDraftContentViewModel(authBox: MastodonAuthenticationBox) -> ComposeContentViewModel? {
        if let _currentDraftContentViewModel, _currentDraftContentViewModel.authenticationBox == authBox {
            return _currentDraftContentViewModel
        } else {
            _currentDraftContentViewModel = ComposeContentViewModel(authenticationBox: authBox, composeContext: .composeStatus(quoting: nil), destination: .topLevel, initialContent: "") { [weak self] outcome in
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
        searchModel = SearchModel(authenticationBox: authenticatedUser)
        discoveryModel = DiscoveryFeedsViewModel()
    }
        
    enum MastodonTab: Identifiable, Hashable {
        case home
        case explore
        case notifications
        case profile
        case lists
        case hashtags
        case list(String)
        case hashtag(String)
        
        var id: String {
            switch self {
            case .home: "home"
            case .explore: "explore"
            case .notifications: "notifications"
            case .profile: "profile"
            case .hashtags: "hashtags"
            case .lists: "lists"
            case .list(let id):
                "list-\(id)"
            case .hashtag(let id):
                "hashtag-\(id)"
            }
        }
    }
    
    var selectedTab: MastodonTab = .home
    
    private var navigationRouters = [ MastodonTab : MastodonNavigationRouter]()
    
    func tabs(forSizeClass sizeClass: UserInterfaceSizeClass?) -> [MastodonTab] {
        switch sizeClass {
        case .regular:
            return [.home, .explore, .notifications, .profile, .lists, .hashtags]
        case .none, .compact:
            fallthrough
        @unknown default:
            return [.home, .explore, .notifications, .profile]
        }
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
        let freshRouter = MastodonNavigationRouter()
        navigationRouters[tab] = freshRouter
        return freshRouter
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
}
