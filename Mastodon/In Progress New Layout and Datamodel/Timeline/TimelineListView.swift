// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import MastoParse
import Combine
import MastodonUI
import Meta
import WebKit

func debugScroll(_ message: String) {
#if DEBUG && false
    print("SCROLL: \(message)")
#endif
}

enum TimelineViewType {
    case home
    case notifications(NotificationsScope)
    case notificationRequests
    case discover(DiscoveryType)
    case linkMentions(String)
    case myBookmarks
    case myFavorites
    case myFollowedHashtags
    case followers(ofUserId: Mastodon.Entity.Account.ID)
    case accountsFollowed(byUserId: Mastodon.Entity.Account.ID)
    case familiarFollowers(MastodonAccount, TimelineListViewModel)
    case search(SearchQueryModel)
    case profilePosts(tabTitle: String?, userID: String, queryFilter: TimelineQueryFilter)
    case postHistory(MastodonContentPost)
    case thread(root: MastodonContentPost)
    case remoteThread(root: RemoteThreadType)
    case hashtag(Mastodon.Entity.Tag)
    case collection(CollectionViewModel)
    case whoFavourited(actionableStatusID: Mastodon.Entity.Status.ID)
    case whoBoosted(actionableStatusID: Mastodon.Entity.Status.ID)
    
    var tabTitle: String? {
        switch self {
        case .profilePosts(let tabTitle, _, _):
            return tabTitle
        default:
            return nil
        }
    }
    
    var navigationTitle: String? {
        switch self {
        case .home:
            return nil
        case .notifications:
            return nil
        case .linkMentions:
            return nil
        case .notificationRequests:
            return L10n.Scene.Notification.FilteredNotification.title
        case .postHistory:
            return L10n.Common.Controls.Status.EditHistory.title
        case .thread(let focusedPost):
            let authorHandle = focusedPost.initialDisplayInfo().actionableAuthorHandle
            return L10n.Scene.Thread.title("@\(authorHandle)")
        case .discover, .profilePosts, .remoteThread:
            return nil
        case .myBookmarks:
            return L10n.Scene.Bookmark.title
            
        case .myFavorites:
            return L10n.Scene.Favorite.title
            
        case .collection(let collectionViewModel):
            return nil // this will be collectionViewModel.collection.name, but until we require iOS26, cannot be displayed as title+subtitle, so will be displayed in a header section
            
        case .whoFavourited:
            return L10n.Scene.FavoritedBy.title
            
        case .whoBoosted:
            return L10n.Scene.RebloggedBy.title
            
        case .followers:
            return L10n.Scene.Follower.title
        case .accountsFollowed:
            return L10n.Scene.Following.title
        case .familiarFollowers(let account, _):
            return account.displayInfo.fullHandle
        case .search(let searchModel):
            return searchModel.trimmedSearchString
        case .hashtag(let tag):
            return "#\(tag.name)"

        case .myFollowedHashtags:
            return L10n.Scene.FollowedTags.title
        }
    }
    
    @MainActor var contentConcealModel: ContentConcealViewModel {
        switch self {
        case .collection(let viewModel):
            if viewModel.collection.sensitive == true {
                return ContentConcealViewModel(initialHideContent: true)
            } else {
                return ContentConcealViewModel.alwaysShow
            }
        default:
            return ContentConcealViewModel.alwaysShow
        }
    }
}

extension TimelineViewType {
    @MainActor
    func timelineViewModel(asyncRefreshViewModel: AsyncRefreshViewModel, navigator: MastodonNavigationRouter) -> TimelineListViewModel {
        switch self {
        case .home:
            TimelineListViewModel(timeline: .homeTimeline, navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .notifications(let scope):
            TimelineListViewModel(timeline: .notifications(scope: scope), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .notificationRequests:
            TimelineListViewModel(timeline: .notificationRequests, navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .discover(let type):
            TimelineListViewModel(timeline: .discover(type), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .linkMentions(let url):
            TimelineListViewModel(timeline: .linkMentions(url), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .search(let searchModel):
            TimelineListViewModel(timeline: .search(searchModel), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .profilePosts(_, let user, let queryFilter):
            TimelineListViewModel(timeline: .userPosts(userID: user, queryFilter: queryFilter), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .postHistory(let post):
            TimelineListViewModel(timeline: .postHistory(post), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .thread(let root):
            TimelineListViewModel(timeline: .thread(root: root), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .remoteThread(let remoteThreadType):
            TimelineListViewModel(timeline: .remoteThread(remoteType: remoteThreadType), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .followers(let followedAccount):
            TimelineListViewModel(timeline: .followers(ofUserId: followedAccount), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .accountsFollowed(let followingAccount):
            TimelineListViewModel(timeline: .accountsFollowed(byUserId: followingAccount), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .familiarFollowers(_, let premadeViewModel):
            premadeViewModel
        case .myFollowedHashtags:
            TimelineListViewModel(timeline: .myFollowedHashtags, navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .myBookmarks:
            TimelineListViewModel(timeline: .myBookmarks, navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .myFavorites:
            TimelineListViewModel(timeline: .myFavorites, navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .hashtag(let tag):
            TimelineListViewModel(timeline: .hashtag(tag, includeHeader: true), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .collection(let collectionViewModel):
            TimelineListViewModel(timeline: .collection(collectionViewModel), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .whoFavourited(let statusID):
            TimelineListViewModel(timeline: .whoFavourited(actionableStatusID: statusID), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        case .whoBoosted(let statusID):
            TimelineListViewModel(timeline: .whoBoosted(actionableStatusID: statusID), navigator: navigator, asyncRefreshViewModel: asyncRefreshViewModel)
        }
    }
}

extension NotificationsScope {
    var pickerLabel: String {
        switch self {
        case .everything:
            L10n.Scene.Notification.Title.everything
        case .mentions:
            L10n.Scene.Notification.Title.mentions
        case .fromRequest:
            ""
        }
    }
}

extension MastodonPostMenuAction {
    enum AlertType {
        case confirmBoostOfPost(didConfirm: (Bool)->())
        case confirmDeleteOfPost(didConfirm: (Bool)->())
        case confirmUnfollow(username: String, didConfirm: (Bool)->())
        case confirmMute(username: String, didConfirm: (Bool)->())
        case confirmUnmute(username: String, didConfirm: (Bool)->())
        case confirmRemoveQuote(username: String, didConfirm: (Bool)->())
        case confirmRemoveMeFromCollection(collectionName: String, didConfirm: (Bool)->())
        case confirmBlock(username: String, didConfirm: (Bool)->())
        case confirmUnblock(username: String, didConfirm: (Bool)->())
        case confirmDomainBlock(account: MastodonAccount, didConfirm: (Bool)->())
        case confirmUnhideFeatureTabBeforeFeaturing(featureItemName: String, didConfirm: (Bool)->())
        case confirmFollowBeforeAddingToList(username: String, didConfirm: (Bool)->())
        case confirmRemoveFollower(username: String, didConfirm: (Bool)->())
        case error(Error)
        
        var title: String {
            switch self {
            case .confirmBoostOfPost:
                L10n.Common.Alerts.BoostAPost.titleBoost
                
            case .confirmDeleteOfPost:
                L10n.Common.Alerts.DeletePost.title
                
            case .confirmUnfollow(let username, _):
                L10n.Common.Alerts.UnfollowUser.title("\(username)")
                
            case .confirmMute:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.title
            case .confirmUnmute:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title
                
            case .confirmRemoveQuote:
                L10n.Common.Alerts.ConfirmRemoveQuote.title
            case .confirmRemoveMeFromCollection(let collectionName, _):
                L10nLookup.Scene.Collections.confirmRemoveFromCollectionTitle(collectionName: collectionName)
            case .confirmBlock:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.title
            case .confirmUnblock:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.title
            case .confirmDomainBlock:
                L10n.Common.Alerts.BlockDomain.blockEntireDomain
            case .confirmUnhideFeatureTabBeforeFeaturing:
                L10nLookup.MastodonMenuAction.confirmShowFeaturedTabTitle
            case .confirmFollowBeforeAddingToList(let username, _):
                L10nLookup.MastodonMenuAction.confirmFollowBeforeAddingToListTitle(username: username)
            case .confirmRemoveFollower:
                L10nLookup.MastodonMenuAction.confirmRemoveFollowerTitle
            case .error:
                L10n.Common.Alerts.genericError
            }
        }
        
        var messageText: String? {
            switch self {
            case .confirmUnfollow, .confirmBoostOfPost:
                nil
                
            case .confirmMute(let username, _):
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.message(username)
            case .confirmUnmute(let username, _):
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(username)
                
            case .confirmBlock(let username, _):
                [1, 2, 3, 4, 5].map{ "- " + L10nLookup.MastodonMenuAction.confirmBlockUserMessage(bulletNumber: $0) }.joined(separator: "\n")
            case .confirmUnblock(let username, _):
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.message(username)
            case .confirmDomainBlock(let account, _):
                L10n.Common.Alerts.BlockDomain.title(account.domain)
                
            case .confirmRemoveQuote:
                L10n.Common.Alerts.ConfirmRemoveQuote.message
            case .confirmRemoveMeFromCollection:
                L10nLookup.Scene.Collections.confirmRemoveFromCollectionMessage
            case .confirmDeleteOfPost:
                L10n.Common.Alerts.DeletePost.message
            case .confirmUnhideFeatureTabBeforeFeaturing(let item, _):
                L10nLookup.MastodonMenuAction.confirmShowFeatureTabMessage(featureItem: item)
            case .confirmFollowBeforeAddingToList(let username, _):
                L10nLookup.MastodonMenuAction.confirmFollowBeforeAddingToListMessage(username: username)
            case .confirmRemoveFollower(let username, _):
                L10nLookup.MastodonMenuAction.confirmRemoveFollowerMessage(username: username)
            case .error(let error):
                error.localizedDescription
            }
        }
    }
}

enum MastodonTimelineSheet: Identifiable {
    case postInteractionSettingsEdit(PostInteractionSettingsViewModel)
    case boostOrQuoteDialog(MastodonPostViewModel)
    case manageListMembership(MastodonAccount)
    
    var id: String {
        switch self {
        case .postInteractionSettingsEdit(let viewModel):
            return "post-interaction-settings-edit"
        case .boostOrQuoteDialog(let viewModel):
            return "boost-or-quote-\(viewModel.initialDisplayInfo.id)"
        case .manageListMembership(let account):
            return "manage-list-membership-\(account.id)"
        }
    }
}

var avatarSize = AvatarSize.large
func useableWidth(fromGeoProxy geo: GeometryProxy) -> CGFloat {
    return geo.size.width - geo.safeAreaInsets.leading - geo.safeAreaInsets.trailing
}

func contentWidth(forUseableWidth useableWidth: CGFloat) -> CGFloat {
    return max(1, useableWidth - (standardPadding /*left margin*/ + spacingBetweenGutterAndContent /*avatar trailing to content leading*/ + doublePadding /*right margin*/) - avatarSize)
}

extension View {
    func timelineEnvironment(timelineModel: TimelineListViewModel,
                             contentConcealModel: ContentConcealViewModel,
                             filter: TimelineQueryFilter?,
                             asyncRefreshModel: AsyncRefreshViewModel?) -> some View {
        self
            .environment(timelineModel)
            .environment(contentConcealModel)
            .environment(filter)
            .environment(asyncRefreshModel)
    }
}

struct TimelineListView: View {
    @Environment(AuthenticationObserver.self) private var authenticationObserver
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(TimelineListViewModel.self) private var viewModel
    @Environment(TimelineQueryFilter.self) private var filterModel
    @Environment(AsyncRefreshViewModel.self) private var asyncRefreshViewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealModel
    
    @State var _updatedGeometry: GeometryProxy?
    @State var _updatedScrollAnchor: TimelineItem?
    @State var _updatedVisibleItems: [TimelineItem]?
    @State var _pendingGeometryUpdates = false
    
    var body: some View {
        @Bindable var navigator = navigator
        GeometryReader { geo in
            ZStack(alignment: .bottom) { // to show donation banner, and snackbar, and fade-in overlays
                if viewModel.feedIsEmpty {
                    switch viewModel.timeline {
                    case .homeTimeline:
                        Image(uiImage: Asset.Asset.friends.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Button {
                            MastodonTabViewRouter.current.openExplore(.forYou)
                        } label: {
                            Text(L10n.Common.Controls.Actions.findPeople)
                                .bold()
                                .foregroundStyle(.white)
                                .padding()
                                .background(Asset.Colors.accent.swiftUIColor)
                                .cornerRadius(CornerRadius.standard)
                        }
                        .padding(EdgeInsets(top: doublePadding, leading: 0, bottom: doublePadding, trailing: 0))
                    default:
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                Asset.Asset.emptyStateMastodon.swiftUIImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geo.size.width * 0.5)
                                if let mainMessage = emptyStateMainMessage(viewModel.timeline) {
                                    Text(mainMessage)
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }
                                if let secondaryMessage = emptyStateSecondaryMessage(viewModel.timeline) {
                                    Text(secondaryMessage)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                                emptyStateControls(viewModel.timeline)
                            }
                            .padding(doublePadding)
                            .frame(maxWidth: geo.size.width)
                        }.nestedScrollview(viewModel.timeline.isInNestedScrollview ? .inner : .notNested)
                            .onScrollPhaseChange({ oldPhase, newPhase in
                                let isNowScrolling = newPhase != .idle
                                if isNowScrolling != viewModel.isCurrentlyScrolling {
                                    viewModel.isCurrentlyScrolling = isNowScrolling
                                }
                            })
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        fixedHeader(geoWidth: min(maxFeedContentWidth, geo.size.width))
                            .frame(maxWidth: maxFeedContentWidth)
                            .frame(maxWidth: .infinity)
                        
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                feedContents(geo)
                            }
                            .scrollTargetLayout()
                        }
                        .nestedScrollview(viewModel.timeline.isInNestedScrollview ? .inner : .notNested)
                        .onScrollPhaseChange({ oldPhase, newPhase in
                            let isNowScrolling = newPhase != .idle
                            if isNowScrolling != viewModel.isCurrentlyScrolling {
                                viewModel.isCurrentlyScrolling = isNowScrolling
                            }
                        })
                        .onScrollGeometryChange(for: Double.self) { scrollGeometry in
                            let result = viewModel.interactiveReloadTriggerModel.visiblePercent(withScrollGeometry: scrollGeometry)
                            return result
                        } action: { oldPercent, newPercent in
                            guard viewModel.currentDisplaySlice.last == .loadingIndicator else { return }
                            if oldPercent != newPercent {
                                viewModel.interactiveReloadTriggerModel.updateVisiblePercent(newPercent)
                            }
                        }
                        .scrollPosition(id: viewModel.scrollAnchorItemBinding, anchor: .top)
                        .onScrollTargetVisibilityChange(idType: TimelineItem.self, threshold: 0.5) { visibleRowIds in
                            queueUpdates(visibleItems: visibleRowIds)
                        }
                        .onChange(of: geo.frame(in: .global), initial: true) { _, newValue in
                            queueUpdates(geometry: geo)
                        }
                        .onChange(of: geo.safeAreaInsets, initial: true) { _, _ in
                            queueUpdates(geometry: geo)
                        }
                        .onChange(of: viewModel.scrollAnchorItem) { _, newValue in
                            queueUpdates(scrollAnchor: newValue)
                        }
                        .conditionallyRefreshable(!viewModel.timeline.canPullToRefresh ? nil : {
                            guard viewModel.loadingState.canReload else { return }
                            viewModel.loadingState = .requestedReloadFromTop
                            await viewModel.refreshFromTop()
                        }
                        )
                        .accessibilityAction(named: L10n.Common.Controls.Actions.loadNewer) {
                            guard viewModel.loadingState.canReload else { return }
                            viewModel.loadingState = .requestedReloadFromTop
                            Task {
                                await viewModel.refreshFromTop()
                            }
                        }
                    }
                    
                    if let campaign = viewModel.presentedDonationCampaign {
                        DonationPromptBanner(campaign: campaign,
                                             close: {
                            withAnimation {
                                viewModel.presentedDonationCampaign = nil
                            }
                            Mastodon.Entity.DonationCampaign.didDismiss(campaign.id)
                        },
                                             showDonationDialog: {
                            withAnimation {
                                viewModel.presentedDonationCampaign = nil
                            }
                            viewModel.presentDonationDialog?(campaign)
                        })
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Snackbars at the top right
                    VStack(alignment: .trailing) {
                        if viewModel.unreadCount > 0 {
                            Snackbar(barType: .newUnreadItems(viewModel.unreadCount))
                                .onTapGesture {
                                    viewModel.scrollToTop()
                                }
                        } else {
                            switch asyncRefreshViewModel.refreshButtonState {
                            case .hidden:
                                EmptyView()
                            case .newResultsExpected:
                                Snackbar(barType: .asyncRefreshUpdateAvailable)
                                    .onTapGesture {
                                        guard asyncRefreshViewModel.willRefreshFromOriginalEndpoint() else {
                                            return
                                        }
                                        guard viewModel.loadingState != .requestedAsyncRefreshResults else { return }
                                        viewModel.loadingState = .requestedAsyncRefreshResults
                                        Task {
                                            await viewModel.forceReload(.asyncRefreshResultsRequested)
                                        }
                                    }
                            case .fetching:
                                Snackbar(barType: .asyncRefreshUpdateFetching)
                            }
                        }
                        Spacer()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(tinySpacing)
                }
            } // ZStack(alignment: .bottom)
        } // GeometryReader
        .onAppear() {
            viewModel.clearPendingActions(navigator)
            if viewModel.timeline.canDisplayDonationBanner {
                Task {
                    await viewModel.askForDonationIfPossible()
                }
            }
            if viewModel.timeline.canDisplayUnreadNotifications {
                // clear the notification dot on the tab icon
                NotificationService.shared.clearNotificationCountForActiveUser()
            }
            if viewModel.needsReloadOnNextAppear {
                viewModel.needsReloadOnNextAppear = false
                Task {
                    await viewModel.forceReload(.notificationCountUpdated)
                }
            }
        }
        .onDisappear() {
            viewModel.loadingState = .untracked
            if viewModel.timeline == .notificationRequests, viewModel.notificationRequestsAcceptanceDidChange {
                viewModel.notificationRequestsAcceptanceDidChange = false
                MastodonTabViewRouter.current.fetchFilteredNotificationsPolicy(andReloadFeed: true)
            }
        }
        .alert(navigator.activeAlert?.title ?? "", isPresented: navigator.alertIsPresented, presenting: navigator.activeAlert) { alert in
            alertContents(alert)
        } message: { alert in
            if let messageText = alert.messageText {
                Text(messageText)
            }
        }
        .sheet(isPresented: $navigator.isPresentingSheet) {
            if let presentedSheet = navigator.presentedSheet {
                switch presentedSheet {
                case .timelineSheet(let sheet):
                    viewModel.activeSheetContents(sheet, navigator: navigator)
                default:
                    navigator.sheetContents(presentedSheet)
                }
            }
        }
        .environment(TimestampUpdater.timestamper(withInterval: 30))
    }
    
    private func emptyStateMainMessage(_ timeline: MastodonTimelineType, ) -> String? {
        switch timeline {
        case .homeTimeline:
            return nil
        case .featuredItems(userID: let userID):
            guard viewModel.currentRelationship(to: userID)?.isMe != true else {
                if AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.collections) == true {
                    return L10nLookup.Timeline.EmptyState.showcaseYourFavoriteAccounts
                } else {
                    return L10nLookup.Scene.Collections.stayTunedForCollections
                }
            }
            fallthrough
        case .myBookmarks:
            fallthrough
        case .myFavorites:
            fallthrough
        case .myFollowedHashtags:
            fallthrough
        case .local:
            fallthrough
        case .list:
            fallthrough
        case .hashtag:
            fallthrough
        case .discover:
            fallthrough
        case .linkMentions:
            fallthrough
        case .search:
            fallthrough
        case .userPosts:
            fallthrough
        case .followers:
            fallthrough
        case .accountsFollowed:
            fallthrough
        case .familiarFollowers:
            fallthrough
        case .postHistory:
            fallthrough
        case .thread:
            fallthrough
        case .remoteThread:
            fallthrough
        case .notifications, .notificationRequests:
            fallthrough
        case .whoFavourited:
            fallthrough
        case .collection:
            fallthrough
        case .whoBoosted:
            return L10nLookup.Timeline.EmptyState.nothingToSeeHere
        }
    }
    
    private func emptyStateSecondaryMessage(_ timeline: MastodonTimelineType) -> String? {
        switch timeline {
        case .featuredItems(userID: let userID):
            if viewModel.currentRelationship(to: userID)?.isMe == true {
                if AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.collections) == true {
                    return L10nLookup.Scene.Collections.collectionsExplainerShort
                } else {
                    return L10nLookup.Scene.Collections.collectionsExplainerLong
                }
            } else {
                if let username = viewModel.account(userID)?.displayInfo.displayName {
                    return L10nLookup.Timeline.EmptyState.featuredTabEmptyStateMessageWithUsername(username)
                } else {
                    return L10nLookup.Timeline.EmptyState.featuredTabEmptyStateMessage
                }
            }
        case .homeTimeline:
            fallthrough
        case .myBookmarks:
            fallthrough
        case .myFavorites:
            fallthrough
        case .myFollowedHashtags:
            fallthrough
        case .local:
            fallthrough
        case .list:
            fallthrough
        case .hashtag:
            fallthrough
        case .discover:
            fallthrough
        case .linkMentions:
            fallthrough
        case .search:
            fallthrough
        case .userPosts:
            fallthrough
        case .followers:
            fallthrough
        case .accountsFollowed:
            fallthrough
        case .familiarFollowers:
            fallthrough
        case .postHistory:
            fallthrough
        case .thread:
            fallthrough
        case .remoteThread:
            fallthrough
        case .notifications, .notificationRequests:
            fallthrough
        case .whoFavourited:
            fallthrough
        case .collection:
            fallthrough
        case .whoBoosted:
            return nil
        }
    }
    
    @ViewBuilder func emptyStateControls(_ timeline: MastodonTimelineType) -> some View {
        switch timeline {
        case .featuredItems(userID: let userID):
            if viewModel.currentRelationship(to: userID)?.isMe == true {
                if false && AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.collections) == true {
                    VStack {
                        Button(L10nLookup.Scene.Collections.createCollection) {
                            // TODO: implement
                        }
                        
                        Button (L10nLookup.Scene.Collections.hideThisTabInstead) {
                            // TODO: implement
                        }
                    }
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
        case .homeTimeline:
            EmptyView()
        case .myBookmarks:
            EmptyView()
        case .myFavorites:
            EmptyView()
        case .myFollowedHashtags:
            EmptyView()
        case .local:
            EmptyView()
        case .list:
            EmptyView()
        case .hashtag:
            EmptyView()
        case .discover:
            EmptyView()
        case .linkMentions:
            EmptyView()
        case .search:
            EmptyView()
        case .userPosts:
            EmptyView()
        case .followers:
            EmptyView()
        case .accountsFollowed:
            EmptyView()
        case .familiarFollowers:
            EmptyView()
        case .postHistory:
            EmptyView()
        case .thread:
            EmptyView()
        case .remoteThread:
            EmptyView()
        case .notifications, .notificationRequests:
            EmptyView()
        case .whoFavourited:
            EmptyView()
        case .whoBoosted:
            EmptyView()
        case .collection:
            EmptyView()
        }
    }
    
    private func queueUpdates(geometry: GeometryProxy? = nil, visibleItems: [TimelineItem]? = nil, scrollAnchor: TimelineItem? = nil) {
        if let geometry {
            _updatedGeometry = geometry
        }
        if let visibleItems {
            _updatedVisibleItems = visibleItems
        }
        if let scrollAnchor {
            _updatedScrollAnchor = scrollAnchor
        }
        guard !_pendingGeometryUpdates else { return }
        _pendingGeometryUpdates = true
        DispatchQueue.main.async {
            _pendingGeometryUpdates = false
            if let geo = self._updatedGeometry {
                self.viewModel.updateUseableWidth(useableWidth(fromGeoProxy: geo))
                self._updatedGeometry = nil
            }
            if let updatedVisibleItems = self._updatedVisibleItems {
                self.viewModel.visibleItemsDidChange(updatedVisibleItems)
                self._updatedVisibleItems = nil
            }
            if let updatedScrollAnchor = self._updatedScrollAnchor {
                viewModel.updateUnreadCount(scrollAnchor: updatedScrollAnchor)
                self._updatedScrollAnchor = nil
            }
        }
    }
    
    func precalculatedHeight(fromCalculations calculations: [PrecalculatedHeight], contentWidth width: CGFloat, contentConcealMode: ContentConcealViewModel.ContentDisplayMode, isShowingTranslation: Bool) -> CGFloat? {
        return calculations.first(where: { precalculated in
            precalculated.contentWidth == width
            && precalculated.contentConcealed.isShowingContent == contentConcealMode.isShowingContent
            && precalculated.contentConcealed.isShowingMedia == contentConcealMode.isShowingMedia
            && precalculated.showingTranslation == isShowingTranslation
        })?.calculatedHeight
    }
    
    @ViewBuilder func feedContents(_ geo: GeometryProxy) -> some View {
        let useableWidth = min(maxFeedContentWidth, useableWidth(fromGeoProxy: geo))
        let contentWidth = contentWidth(forUseableWidth: useableWidth)
        
        switch contentConcealModel.currentMode {
        case .concealAll(_, showAnyway: true), .neverConceal, .concealMediaOnly:
            ForEach(viewModel.currentDisplaySlice, id: \.self) { item in
                switch item {
                case .loadingIndicator:
                    InteractiveLoadingIndicatorRow()
                        .environment(viewModel.interactiveReloadTriggerModel)
                        .accessibilityAction(named: L10n.Common.Controls.Actions.loadOlder) {
                            switch viewModel.loadingState {
                            case .untracked:
                                viewModel.loadMoreFromBottom()
                            default:
                                break
                            }
                        }
                    
                case .heading(let text):
                    Text(text)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(standardPadding)
                        .frame(width: useableWidth, alignment: .leading)
                    
                case .scopedSearchResults(let queryModel):
                    ScopedSearchResultsRowView(useableWidth: useableWidth, isStandalone: false)
                        .environment(queryModel)
                        .onTapGesture {
                            navigator.push(.timeline(.search(SearchQueryModel(scope: queryModel.scope, trimmedSearchString: queryModel.trimmedSearchString))))
                        }
                    
                case .filteredNotificationsInfo(_, let filteredNotificationsViewModel):
                    if let filteredNotificationsViewModel {
                        FilteredNotificationsRowView(contentWidth: contentWidth)
                            .environment(filteredNotificationsViewModel)
                            .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                            .frame(width: useableWidth)
                            .accessibilityElement(children: .combine)
                            .accessibilityAction {
                                navigateToFilteredNotifications()
                            }
                            .onTapGesture {
                                navigateToFilteredNotifications()
                            }
                    } else {
                        Text(L10nLookup.Timeline.EmptyState.someNotificationsHaveBeenFiltered)
                            .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                            .frame(width: useableWidth)
                    }
                    Divider()
                    
                case .notificationRequest(let notificationRequestModel):
                    NotificationRequestRowView(contentWidth: contentWidth)
                        .environment(notificationRequestModel)
                    
                case .pinnedPosts:
                    pinnedPostsView(item.postViewModels, contentWidth: contentWidth, useableWidth: useableWidth, isScrollAnchor: viewModel.scrollAnchorItem == item)
                    
                case .post(let postViewModel, let isPinned):
                    switch postViewModel.displayType {
                    case .editHistory(let isOriginal):
                        VStack(alignment: .leading, spacing: 0) {
                            let dateString = postViewModel.formattedExactDate
                            let text = isOriginal ? L10n.Common.Controls.Status.EditHistory.originalPost("\(dateString)") : L10n.Common.Controls.Status.editedAtTimestampPrefix("\(dateString)")
                            Text(text)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.leading, standardPadding)
                                .padding(.top, standardPadding)
                            singlePostView(postViewModel, contentWidth: contentWidth, useableWidth: useableWidth, isPinned: isPinned, isScrollAnchor: viewModel.scrollAnchorItem == item)
                        }
                    case .standard:
                        singlePostView(postViewModel, contentWidth: contentWidth, useableWidth: useableWidth, isPinned: isPinned, isScrollAnchor: viewModel.scrollAnchorItem == item)
                    }
                    
                case .notification(let notificationViewModel):
                    NotificationRowView(contentWidth: contentWidth, actionHandler: viewModel)
                        .environment(notificationViewModel)
                        .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: useableWidth)
                        .background() {
                            if let inlinePost = notificationViewModel.inlinePostViewModel {
                                switch inlinePost.initialDisplayInfo.actionableVisibility {
                                case .mentionedOnly:
                                    backgroundView(isPrivate: true, isUnread: false) // TODO: implement unread for notifications
                                default:
                                    EmptyView()
                                }
                            }
                        }
                case .hashtag(let tagViewModel):
                    switch viewModel.timeline {
                    case .hashtag:
                        HashtagHeaderView(availableWidth: useableWidth - doublePadding * 2)
                            .environment(tagViewModel)
                            .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                            .frame(width: useableWidth)
                        Divider()
                    case .myFollowedHashtags:
                        HashtagHeaderView(availableWidth: useableWidth - doublePadding * 2)
                            .environment(tagViewModel)
                            .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                            .frame(width: useableWidth)
                    default:
                        HashtagRowView()
                            .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                            .frame(width: useableWidth)
                            .environment(tagViewModel)
                            .onTapGesture {
                                navigator.push(.timeline(.hashtag(tagViewModel.entity)))
                            }
                    }
                    
                case .link(let link):
                    VStack(alignment: .trailing) {
                        LinkPreviewCard(cardEntity: link, fittingWidth: useableWidth)
                        HStack {
                            Text(L10n.Plural.peopleTalking(link.talkingPeopleCount ?? 0))
                                .onTapGesture {
                                    navigator.push(.timeline(.linkMentions(link.url)))
                                }
                            Image(systemName: "chevron.forward")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical)
                    }
                    .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                    .frame(width: useableWidth)
                    
                case .account(let accountViewModel):
                    if let collectionViewModel = viewModel.timeline.collectionViewModel, collectionViewModel.iHaveRemovedMyself, accountViewModel.id == AuthenticationServiceProvider.shared.currentActiveUser.value?.userID {
                        EmptyView()
                    } else {
                        // TODO: larger, more informative view if in a .discovery timeline?
                        AccountRowView(contentWidth: contentWidth, collectionViewModel: viewModel.timeline.collectionViewModel)
                            .environment(accountViewModel)
                            .padding(EdgeInsets(top: standardPadding, leading: doublePadding, bottom: standardPadding, trailing: standardPadding))
                            .frame(width: useableWidth)
                            .onTapGesture {
                                navigator.push(.profile(account: accountViewModel.account._legacyEntity, relationship: nil))
                            }
                    }
                case .collection(let collectionViewModel):
                    CollectionRowView(contentWidth: contentWidth, includeMenu: true)
                        .environment(collectionViewModel)
                        .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: useableWidth)
                        .onTapGesture {
                            navigator.push(.timeline(.collection(collectionViewModel)))
                        }
                    
                case .noItem:
                    EmptyView()
                }
            }
            if viewModel.threadedConversationModel != nil {
                // include a spacer to indicate the end of the conversation and provide scrolling space so that if the focused post is at the end of the conversation it can still be scrolled to the top (or something near it)
                Color.clear
                    .frame(height: geo.size.height * 0.5)
            }
        case .concealAll(_, showAnyway: false):
            concealedContentsView()
                .padding(standardPadding)
        }
    }
    
    @ViewBuilder func concealedContentsView() -> some View {
        switch viewModel.timeline {
        case .collection:
            infoPlusActionCalloutView(
                image: Image(systemName: "eye.slash"),
                headline: L10nLookup.Scene.Collections.sensitiveContentHeading,
                message: L10nLookup.Scene.Collections.sensitiveContentMessage,
                backgroundColor: Asset.Colors.FigmaToken.bgWarningSoftest.swiftUIColor,
                buttonText: L10n.Common.Controls.Status.showAnyway,
                buttonColor: Asset.Colors.FigmaToken.bgWarningSoft.swiftUIColor
            ) {
                contentConcealModel.currentMode = .concealAll(reasons: [], showAnyway: true)
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder func infoPlusActionCalloutView(image: Image, headline: String, message: String, backgroundColor: Color, buttonText: String, buttonColor: Color, buttonAction: @escaping ()->()) -> some View {
        HStack(alignment: .top) {
            image
                .padding(tinySpacing)
                .background() {
                    Circle()
                        .fill(buttonColor)
                }
            
            VStack(alignment: .leading) {
                Text(headline)
                    .fontWeight(.semibold)
                Text(message)
                    .font(.subheadline)
                Button() {
                   buttonAction()
                } label: {
                    Text(buttonText)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background() {
                            Capsule()
                                .fill(buttonColor)
                        }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background() {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(backgroundColor)
        }
    }
    
    @ViewBuilder func singlePostView(_ postViewModel: MastodonPostViewModel, contentWidth: CGFloat, useableWidth: CGFloat, isPinned: Bool, isScrollAnchor: Bool) -> some View {
#if DEBUG && false
        Text(postViewModel.initialDisplayInfo.id)
            .foregroundStyle(.red)
            .fontWeight(.bold)
        if let actionablePostID = postViewModel.fullPost?.actionablePost?.id, actionablePostID != postViewModel.initialDisplayInfo.id {
            Text("actionable: \(actionablePostID)")
                .foregroundStyle(.red)
                .font(.footnote)
        }
#endif
        
        let contentConcealModel = viewModel.contentConcealModel(forActionablePost: postViewModel.initialDisplayInfo.actionablePostID)
        let expectedHeight: CGFloat? = postViewModel.initialDisplayInfo.id == viewModel.threadedConversationModel?.focusedID ? nil :  precalculatedHeight(fromCalculations: postViewModel.precalculatedHeights, contentWidth: contentWidth, contentConcealMode: contentConcealModel.currentMode, isShowingTranslation: postViewModel.isShowingTranslation == true)
        MastodonPostRowView(contentWidth: contentWidth, precalculatedHeight: expectedHeight, isPinned: isPinned, actionHandler: viewModel, threadedContext: viewModel.threadedConversationModel?.context(for: postViewModel.initialDisplayInfo.id), filterContext: viewModel.timeline.filterContext)
            .environment(postViewModel)
            .environment(contentConcealModel)
            .padding(EdgeInsets(top: 0, leading: standardPadding, bottom: 0, trailing: doublePadding))
            .frame(width: useableWidth, height: expectedHeight, alignment: .top)
#if DEBUG
            .background {
                ZStack(alignment: .topTrailing) {
                    HStack {
                        Spacer()
                            .frame(width: AvatarSize.large + spacingBetweenGutterAndContent)
                        Rectangle()
                            .fill(isScrollAnchor ? .yellow.opacity(0.2) : .clear)
                            .frame(width: spacingBetweenGutterAndContent)
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                    
                    if let expectedHeight {
                        let difference: CGFloat? = {
                            guard let actual = postViewModel.actualLayoutHeight else { return nil }
                            return actual - expectedHeight
                        }()
                        Text("calculated: \(expectedHeight)\nactual: \(String(describing: postViewModel.actualLayoutHeight))\ndifference: \(String(describing: difference))")
                            .foregroundStyle(.red)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white.opacity(0.3))
                            }
                        FrameReader() { newFrame in
                            postViewModel.actualLayoutHeight = newFrame.size.height
                        }
                    }
                }
            }
#endif
            .contentShape(Rectangle())
            .onTapGesture {
                switch viewModel.timeline {
                case .thread(let root):
                    guard root.id != postViewModel.initialDisplayInfo.id else { return }
                case .remoteThread(remoteType: .status(let id)):
                    guard id != postViewModel.initialDisplayInfo.id else { return }
                default:
                    break
                }
                postViewModel.openThreadView(navigator: navigator)
            }
            .background() {
                switch viewModel.timeline {
                case .notifications:
                    switch postViewModel.initialDisplayInfo.actionableVisibility {
                    case .mentionedOnly:
                        backgroundView(isPrivate: true, isUnread: false) // TODO: implement unread for notifications
                    default:
                        EmptyView()
                    }
                default:
                    EmptyView()
                }
            }
    }
    
    @ViewBuilder func pinnedPostsView(_ postViewModels: [MastodonPostViewModel], contentWidth: CGFloat, useableWidth: CGFloat, isScrollAnchor: Bool) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            if viewModel.pinnedPostsAreCollapsed, let firstPostModel = postViewModels.first {
                singlePostView(firstPostModel, contentWidth: contentWidth, useableWidth: useableWidth, isPinned: true, isScrollAnchor: false)
                
                if postViewModels.count > 1 {
                    Button() {
                        viewModel.pinnedPostsAreCollapsed = false
                    } label: {
                        HStack {
                            Image(systemName: "pin")
                            Text(L10nLookup.Scene.Profile.viewAllPinnedPosts(pinnedPostCount: postViewModels.count))
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, standardPadding)
                        .padding(.horizontal)
                        .frame(width: useableWidth - standardPadding - standardPadding)
                        .background() {
                            MastodonSecondaryBackground(fillInDarkModeOnly: true)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: standardPadding, bottom: doublePadding, trailing: standardPadding))
                }
            } else {
                ForEach(postViewModels, id: \.self.initialDisplayInfo.id) { postModel in
                    singlePostView(postModel, contentWidth: contentWidth, useableWidth: useableWidth, isPinned: true, isScrollAnchor: false)
                }
            }
        }
    }
    
    @ViewBuilder func fixedHeader(geoWidth: CGFloat) -> some View {
        if UserDefaults.standard.showRateLimitTracker {
            RateLimitTracker()
                .environment(RateLimitViewModel.shared)
                .padding(.horizontal, doublePadding)
        }
        
        // PROFILE TIMELINE - FILTER BOOSTS AND REPLIES
        if filterModel.showBoostsAndRepliesFilterButton {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: doublePadding)
                
                BoostsAndRepliesFilterButton()
                
                Spacer()
                    .frame(height: doublePadding)
            }
            .id("repliesAndBoostsFilterButton")
            .padding(.horizontal, doublePadding)
        }
        
        // PROFILE TIMELINE - FEATURED HASHTAGS
        FeaturedHashtagsFlow(maxItemWidth: min(maxFeedContentWidth, geoWidth) - doublePadding * 2)
            .environment(filterModel)
            .environment(filterModel.featuredHashtagsModel ?? FeaturedHashtagsModel())
            .padding(.horizontal, doublePadding)
        
        // FAMILIAR FOLLOWERS - subheadline
        switch viewModel.timeline {
        case .familiarFollowers:
            if let totalFamiliars = viewModel.familiarFollowers?.totalCount {
                Text(L10nLookup.Scene.FamiliarFollowers.followersYouKnow(totalFamiliars))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, doublePadding)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .collection(let collectionViewModel):
            VStack(alignment: .leading, spacing: standardPadding) {
                VStack(alignment: .leading, spacing: 0) {
                    if let collectionName = collectionViewModel.collection.name {
                        Text(collectionName)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
                    if let author = collectionViewModel.authorHandle {
                        Text(L10nLookup.Scene.Collections.authorLabel(author))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                if let description = collectionViewModel.collection.description, !description.isEmpty {
                    Text(description)
                }
                let myAccountId = AuthenticationServiceProvider.shared.currentActiveUser.value?.userID
                if !collectionViewModel.iHaveRemovedMyself, let meAsMember = collectionViewModel.collection.items.first(where: { $0.account_id == myAccountId }) {
                    infoPlusActionCalloutView(
                        image: Image(systemName: "star"),
                        headline: L10nLookup.Scene.Collections.youAreFeaturedInThisCollection,
                        message: L10nLookup.Scene.Collections.collectionAuthorAddedYouOnDate(author: collectionViewModel.authorHandle ?? "", date: meAsMember.created_at),
                        backgroundColor: Asset.Colors.FigmaToken.bgBrandSoftest.swiftUIColor,
                        buttonText: L10nLookup.Scene.Collections.removeMe,
                        buttonColor: Asset.Colors.FigmaToken.bgBrandSoft.swiftUIColor
                    ) {
                        collectionViewModel.doRemoveMe(meItemID: meAsMember.id, navigator: navigator)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                Text(L10nLookup.Scene.Collections.numberOfAccounts(collectionViewModel.itemCount))
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, standardPadding)
            .padding(.bottom, doublePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            EmptyView()
        }
        
    }
    
    private func navigateToFilteredNotifications() {
        navigator.push(.timeline(.notificationRequests))
    }
    
    @ViewBuilder func backgroundView(isPrivate: Bool, isUnread: Bool) -> some View {
        HStack(spacing: 0) {
//            if isUnread && UserDefaults.standard.testUnreadMarkersForNotifications {
//                Rectangle()
//                    .fill(Asset.Colors.accent.swiftUIColor)
//                    .frame(width: 8)
//            }
            Rectangle()
                .fill(isPrivate ?  Asset.Colors.accent.swiftUIColor : .clear)
                .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                .opacity(0.1)
        }
    }
    
    @ViewBuilder func alertContents(_ alert: MastodonPostMenuAction.AlertType) -> some View {
        switch alert {
        case .confirmBoostOfPost(let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Alerts.BoostAPost.boost)
            }
            
            
        case .confirmRemoveQuote(_, let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Actions.remove)
            }
            
        case .confirmRemoveMeFromCollection(_, let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10nLookup.Scene.Collections.removeMe)
            }
            
        case .confirmDeleteOfPost(let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Actions.delete)
            }
            
        case .confirmUnfollow(_, let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Alerts.UnfollowUser.unfollow)
            }
            
        case .confirmMute(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.muteUser(username))
            }
        case .confirmUnmute(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.unmuteUser(username))
            }
            
        case .confirmBlock(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.blockUser(username))
            }
        case .confirmUnblock(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.unblockUser(username))
            }
        case .confirmDomainBlock(let account, let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Alerts.BlockDomain.blockEntireDomain)
            }
            
        case .error:
            if UserDefaults.standard.showRateLimitTracker {
                Button("Copy recent requests") {
                    UIPasteboard.general.string = RateLimitViewModel.shared.previousRequests.joined(separator: "\n")
                }
            }
            Button(L10n.Common.Controls.Actions.ok) {
            }
        case .confirmUnhideFeatureTabBeforeFeaturing(_, let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10nLookup.MastodonMenuAction.confirmShowFeaturedTabButton)
            }
        case .confirmFollowBeforeAddingToList(_, let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10nLookup.MastodonMenuAction.confirmFollowButton)
            }
        case .confirmRemoveFollower(_, let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10nLookup.MastodonMenuAction.removeFollower)
            }
        }
    }
    
    @ViewBuilder func cancelButton(_ didConfirm: @escaping (Bool)->()) -> some View {
        Button(role: .cancel) {
            viewModel.clearPendingActions(navigator)
            didConfirm(false)
        }
        label: {
            Text(L10n.Common.Controls.Actions.cancel)
        }
    }
}



extension GenericMastodonPost {
    var actionablePost: MastodonContentPost? {
        let actionablePost: MastodonContentPost?
        if let contentPost = self as? MastodonContentPost {
            actionablePost = contentPost
        } else if let boost = self as? MastodonBoostPost {
            actionablePost = boost.boostedPost
        } else {
            assertionFailure("not implemented")
            actionablePost = nil
        }
        return actionablePost
    }
}

struct TranslationInfoView: View {
    let translationInfo: Mastodon.Entity.Translation
    let showOriginal: ()->()
    
    var body: some View {
        HStack(alignment: .top) {
            Text(translatedFromLanguageByProvider)
                .lineLimit(1)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                showOriginal()
            } label: {
                Text(L10n.Common.Controls.Status.Translation.showOriginal)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
            }
            .fixedSize()
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(translatedFromLanguageByProvider + ", " + L10n.Common.Controls.Status.Translation.showOriginal)
        .accessibilityAction {
            showOriginal()
        }
    }
    
    var translatedFromLanguageByProvider: String {
        let languageName = languageName(translationInfo.sourceLanguage) ?? L10n.Common.Controls.Status.Translation.unknownLanguage
        return L10n.Common.Controls.Status.Translation.translatedFrom(languageName, translationInfo.provider ?? L10n.Common.Controls.Status.Translation.unknownProvider)
    }
}

extension ContentConcealViewModel {
    func buttonText(whenHiding: Bool) -> String? {
        switch currentMode {
        case .neverConceal, .concealMediaOnly:
            return nil
        case .concealAll:
            if currentModeIsFilter {
                return whenHiding ? L10n.Common.Controls.Status.showAnyway : L10n.Common.Controls.Status.Actions.hide
            } else {
                return whenHiding ? L10n.Common.Controls.Status.showMore : L10n.Common.Controls.Status.Actions.hide
            }
        }
    }
}

struct GapLoaderView: View {
    let newerThan: String
    let olderThan: String
    let gapDescription: String
    let loadFromTop: ()->()
    let loadFromBottom: ()->()
    
    var body: some View {
        HStack {
            
            VStack {
                Button {
                    loadFromTop()
                } label: {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.title2)
                        .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                    .frame(minHeight: standardPadding, maxHeight: .infinity)
            }
            
            Spacer()
                .frame(maxWidth: .infinity)
            
            VStack {
                Text(L10n.Common.Controls.Timeline.Loader.loadMissingPosts)
                    .lineLimit(1)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("older than: \(olderThan)")
                    .lineLimit(1)
                    .fixedSize()
                    .font(.footnote)
                Text("newer than: \(newerThan)")
                    .lineLimit(1)
                    .fixedSize()
                    .font(.footnote)
                Text(gapDescription)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
                .frame(maxWidth: .infinity)
            
            VStack {
                Spacer()
                    .frame(minHeight: standardPadding, maxHeight: .infinity)
                
                Button {
                    loadFromBottom()
                } label: {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.title2)
                        .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

struct Snackbar: View {
    enum SnackbarType {
        case newUnreadItems(Int)
        case asyncRefreshUpdateAvailable
        case asyncRefreshUpdateFetching
        
        var hidesText: Bool {
            switch self {
            case .newUnreadItems, .asyncRefreshUpdateAvailable:
                return false
            case .asyncRefreshUpdateFetching:
                return true
            }
        }
    }
    
    let barType: SnackbarType
    
    var body: some View {
        let text = {
            switch barType {
            case .newUnreadItems(let unreadCount):
                return L10nLookup.Common.Controls.Timeline.Loader.unreadItemsButtonTitle(unreadCount: unreadCount)
            case .asyncRefreshUpdateAvailable, .asyncRefreshUpdateFetching:
                return L10nLookup.Common.Controls.Timeline.Loader.showMoreReplies
            }
        }()
        
        ZStack {
            HStack(spacing: tinySpacing) {
                switch barType {
                case .newUnreadItems:
                    Image(systemName: "chevron.up")
                case .asyncRefreshUpdateAvailable, .asyncRefreshUpdateFetching:
                    EmptyView()
                }
                if barType.hidesText {
                    Text(text)
                        .hidden()
                } else {
                    Text(text)
                }
            }
            .font(.footnote)
            .foregroundStyle(.white)
            .padding(EdgeInsets(top: tinySpacing, leading: standardPadding, bottom: tinySpacing, trailing: standardPadding))
            .background {
                Capsule()
                    .fill(Asset.Colors.accent.swiftUIColor)
            }
            
            switch barType {
            case .newUnreadItems, .asyncRefreshUpdateAvailable:
                EmptyView()
            case .asyncRefreshUpdateFetching:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
    }
}

extension MastodonTimelineType {
    var canDisplayNewItemsSnackbar: Bool {
        switch self {
        case .homeTimeline:
            true
        default:
            false
        }
    }
}

extension MastodonTimelineType {
    var canPullToRefresh: Bool {
        switch self {
        case .userPosts, .thread, .remoteThread:
            false
        default:
            true
        }
    }
    
    var isInNestedScrollview: Bool {
        switch self {
        case .userPosts, .featuredItems:
            true
        default:
            false
        }
    }
}

extension MastodonTimelineType {
    @MainActor
    var filterModel: TimelineQueryFilter {
        switch self {
        case .userPosts(_, let queryFilter):
            queryFilter
        default:
            TimelineQueryFilter(.unfilterable)
        }
    }
    
    var accountID: Mastodon.Entity.Account.ID? {
        switch self {
        case .userPosts(let userID, _):
            return userID
        default:
            return nil
        }
    }
}

struct FeaturedHashtagsFlow: View {
    @Environment(\.displayScale) var displayScale
    @Environment(TimelineListViewModel.self) var viewModel
    @Environment(TimelineQueryFilter.self) var filterModel
    @Environment(FeaturedHashtagsModel.self) var featuredHashtagsModel
    
    @State var isCollapsed = true
    @State var hiddenItemCountWithoutButton: Int = 0
    @State var hiddenItemCountWithButton: Int = 0
    
    let interItemSpacing: CGFloat = 4
    
    var maxItemWidth: CGFloat
    
    var body: some View {
        VStack {
            if !featuredHashtagsModel.featuredHashtags.isEmpty {
                if isCollapsed {
                    ZStack(alignment: .leading) {
                        if hiddenItemCountWithoutButton == 0 {
                            SingleRowFlowLayout(hiddenItemCount: $hiddenItemCountWithoutButton, minItemCountPerRow: 1, interItemSpacing: interItemSpacing) {
                                allItems
                            }
                        } else {
                            HStack(spacing: interItemSpacing) {
                                SingleRowFlowLayout(hiddenItemCount: $hiddenItemCountWithButton, minItemCountPerRow: 1, interItemSpacing: interItemSpacing) {
                                    allItems
                                }
                                showAllButton
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    FlowLayout(minItemCountPerRow: 1, interItemSpacing: interItemSpacing) {
                       allItems
                    }
                }
                Spacer()
                    .frame(height: doublePadding)
            } else {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder var allItems: some View {
        ForEach(featuredHashtagsModel.featuredHashtags, id: \.self) { hashtag in
            card(hashtag)
                .onTapGesture {
                    if filterModel.selectedHashtag == hashtag {
                        filterModel.selectedHashtag = nil
                    } else {
                        filterModel.selectedHashtag = hashtag
                    }
                    Task {
                        await viewModel.forceReload(.activityFilterUpdated)
                    }
                }
        }
    }
    
    @ViewBuilder var showAllButton: some View {
        Button {
            isCollapsed = false
        } label: {
            ZStack {
                Text("+\(hiddenItemCountWithButton)")
                Text("+000")
                    .hidden()
            }
            .font(.subheadline)
            .foregroundStyle(.primary )
            .padding(.vertical, tinySpacing)
            .padding(.horizontal, standardPadding)
            .background {
                Capsule()
                    .fill(.secondary.opacity(0.2))
            }
        }
    }
    
    @ViewBuilder func card(_ hashtag: Mastodon.Entity.FeaturedTag) -> some View {
        let isSelected = filterModel.selectedHashtag == hashtag
        Text("#\(hashtag.name)")
        .font(.subheadline)
        .foregroundStyle(isSelected ? .white : .primary )
        .padding(.vertical, tinySpacing)
        .padding(.horizontal, standardPadding)
        .background {
            Capsule()
                .fill(isSelected ? Asset.Colors.accent.swiftUIColor : .secondary.opacity(0.2))
        }
    }
}

struct BoostsAndRepliesFilterButton: View {
    @Environment(TimelineQueryFilter.self) var filterModel
    @Environment(TimelineListViewModel.self) var viewModel
    
    var body: some View {
        HStack() {
            Button() {
                viewModel.isPresentingActivityFilter = !viewModel.isPresentingActivityFilter
            } label: {
                HStack() {
                    Text(viewModel.activityFilterButtonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .fixedSize()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .padding(tinySpacing)
                        .background() {
                            Circle()
                                .fill(.secondary.quinary)
                        }
                }
            }
            .popover(isPresented: Binding<Bool>(
                get: { viewModel.isPresentingActivityFilter },
                set: { isPresented in viewModel.isPresentingActivityFilter = isPresented }
            ),
                     arrowEdge: .top) {
                VStack {
                    Toggle(L10nLookup.Scene.Profile.ActivityFilter.showRepliesToggleLabel,
                           isOn: Binding<Bool>(
                            get: { viewModel.includeReplies },
                            set: { newValue in viewModel.includeReplies = newValue }
                           )
                    )
                    .tint(Asset.Colors.accent.swiftUIColor)
                    Toggle(L10nLookup.Scene.Profile.ActivityFilter.showBoostsToggleLabel,
                           isOn: Binding<Bool>(
                            get: { viewModel.includeBoosts },
                            set: { newValue in viewModel.includeBoosts = newValue }
                           )
                    )
                    .tint(Asset.Colors.accent.swiftUIColor)
                    Spacer()
                        .frame(maxHeight: .infinity)
                }
                .padding(doublePadding * 2)
                .presentationDetents([.fraction(0.25)])
            }
            
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}

