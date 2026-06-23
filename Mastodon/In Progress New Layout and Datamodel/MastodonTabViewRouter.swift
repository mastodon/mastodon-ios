// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

@MainActor
@Observable class MastodonTabViewRouter {
    
    public static let shared = MastodonTabViewRouter()
    
    public var homeTimelineModel: TimelineListViewModel?
    
    enum MastodonTab: Identifiable, Hashable {
        case home
        case explore
        case compose
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
            case .compose: "compose"
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
            return [.home, .explore, .compose, .notifications, .profile, .lists, .hashtags]
        case .none, .compact:
            fallthrough
        @unknown default:
            return [.home, .explore, .compose, .notifications, .profile]
        }
    }
    
    public func show(_ destination: MastodonNavigationDestination, in tab: MastodonTab) {
        navigationRouter(forTab: tab).push(destination)
    }
    
    public func navigationRouter(forTab tab: MastodonTab) -> MastodonNavigationRouter {
        if let existing = navigationRouters[tab] {
            return existing
        }
        let freshRouter = MastodonNavigationRouter(navigationType: .swiftUI(legacyPresenter: nil))
        navigationRouters[tab] = freshRouter
        return freshRouter
    }
   
    /// public set is allowed so that this can be easily bindable, but callers should avoid setting this directly, use presentModal(_,afterDeconflictionDelay:) or dismissCurrentModal() instead.
    public var presentedModal: MastodonNavigationDestination?
    
    public func presentModal(_ modal: MastodonNavigationDestination, afterDeconflictionDelay: Bool) {
        assert(presentedModal == nil, "caller is responsible for dismissing any modals current presented")
        if afterDeconflictionDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) { // without this delay, the modal presentation gets tangled up with any dismissing sheet
                self.presentedModal = modal
            }
        } else {
            presentedModal = modal
        }
    }
    
    public func dismissCurrentModal() {
        guard presentedModal != nil else { return }
        presentedModal = nil
    }
}
