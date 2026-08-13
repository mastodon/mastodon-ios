// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonUI
import MastodonSDK
import Combine

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
    public var customTimelineModels = [ MastodonTab : TimelineListViewModel]()
    
    public var isLocalTimelineAvailable: Bool = false
    public var lists: [Mastodon.Entity.List] = []
    public var followedHashtags: [Mastodon.Entity.Tag] = []
    
    private var _combineSubscriptions = Set<AnyCancellable>()
    
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
        searchModel = SearchModel(authenticationBox: authenticatedUser)
        discoveryModel = DiscoveryFeedsViewModel()
        if let authenticatedUser {
            updateIsLocalTimelineAvailable(authenticatedUser)
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
                    self.updateIsLocalTimelineAvailable(authenticatedUser)
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
    
    private func updateIsLocalTimelineAvailable(_ authenticatedUser: MastodonAuthenticationBox) {
        isLocalTimelineAvailable = authenticatedUser.authentication.instanceConfiguration?.isAvailable(.localTimeline) ?? true
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
        
        
    }
    
    var selectedTab: MastodonTab = .home
    
    private var navigationRouters = [ MastodonTab : MastodonNavigationRouter]()
    
    func tabs(forSizeClass sizeClass: UserInterfaceSizeClass?) -> [MastodonTab] {
        switch sizeClass {
        case .regular:
            return [.home, isLocalTimelineAvailable ? .localFeed : nil, .explore, .notifications, .profile, .lists, .hashtags]
                .compactMap { $0 }
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
