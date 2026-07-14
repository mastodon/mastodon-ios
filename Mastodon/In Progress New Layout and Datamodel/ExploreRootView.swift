// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore

struct ExploreRootView: View {
    @Environment(MastodonNavigationRouter.self) var navigationStackNavigator
    @Environment(SearchModel.self) var searchModel
    
    @State var searchTimelineModel: TimelineListViewModel?
    @State var asyncRefreshModel = AsyncRefreshViewModel()
    
    var body: some View {
        @Bindable var searchModel = searchModel
        contents
            .searchable(text: $searchModel.searchText, isPresented: $searchModel.isSearchActive)
            .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                navigationStackNavigator.destinationView(destination, sceneCoordinator: nil)
            }
            .task(id: searchModel.searchText) {
                if searchTimelineModel == nil {
                    searchTimelineModel = TimelineListViewModel(timeline: .search(searchModel.searchText, .all), navigator: navigationStackNavigator, asyncRefreshViewModel: asyncRefreshModel)
                }
                do { try await Task.sleep(for: .milliseconds(300)) } catch { return } // wait for a pause in typing before performing the search
                searchTimelineModel?.setTimeline(.search(searchModel.searchText, .all), navigator: navigationStackNavigator)
            }
            .onChange(of: navigationStackNavigator.navigationPath) { oldValue, newValue in
                // record this as a recent search if appropriate
                let isNavigatingFromSearchScreen = oldValue.isEmpty
                let searchIsShowingNewResults = !searchModel.searchText.isEmpty
                guard isNavigatingFromSearchScreen, searchIsShowingNewResults, let authenticatedUser = AuthenticationObserver.shared.currentActiveUser else { return }
                switch newValue.first {
                case .profile(let account, _):
                    searchModel.didSelectSearchResult(authenticatedUser, account: account, hashtag: nil)
                case .timeline(.hashtag(let tag)):
                    searchModel.didSelectSearchResult(authenticatedUser, account: nil, hashtag: tag)
                default:
                    break
                }
            }
    }
    
    @ViewBuilder var contents: some View {
        if !searchModel.searchText.isEmpty || (searchModel.isSearchActive && !searchModel.searchHistory.isEmpty) {
            if searchModel.searchText.isEmpty {
                searchHistory
            } else {
                if let searchTimelineModel {
                    TimelineListView()
                        .timelineEnvironment(timelineModel: searchTimelineModel, contentConcealModel: .alwaysShow, filter: searchTimelineModel.timeline.filterModel, asyncRefreshModel: asyncRefreshModel)
                }
            }
        } else {
            DiscoveryFeedsView()
        }
    }
    
    @ViewBuilder var searchHistory: some View {
        GeometryReader { geo in
            let useableWidth = min(maxFeedContentWidth, useableWidth(fromGeoProxy: geo))
            let contentWidth = contentWidth(forUseableWidth: useableWidth)
            LazyVStack {
                ForEach(searchModel.searchHistory, id: \.mastodonID) { item in
                    switch item {
                    case .account(let model):
                        AccountRowView(contentWidth: contentWidth, collectionViewModel: nil)
                            .environment(model)
                    case .hashtag(let tagModel):
                        HashtagRowView()
                            .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                            .frame(width: useableWidth)
                            .environment(tagModel)
                            .onTapGesture {
                                navigationStackNavigator.push(.timeline(.hashtag(tagModel.entity)))
                            }
                    default:
                        Text("Unimplemented search result type")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
}

@MainActor
@Observable class SearchModel {
    var searchText = ""
    var isSearchActive: Bool = false
    var searchHistory: [TimelineItem] = []
    
    var accountModels = [ Mastodon.Entity.Account.ID : AccountRowViewModel]()
    var hashtagModels = [ String : HashtagRowViewModel ]()
    
    init(authenticationBox: MastodonAuthenticationBox?) {
        if let authenticationBox {
           updateHistory(authenticationBox)
        }
    }
    
    private func updateHistory(_ authBox: MastodonAuthenticationBox) {
        let historyItems = (try? FileManager.default.searchItems(for: authBox)) ?? []
        searchHistory = historyItems.compactMap({ item -> TimelineItem? in
            if let account = item.account {
                if let existing = accountModels[account.id] {
                    return .account(existing)
                } else {
                    let model = AccountRowViewModel(account: MastodonAccount.fromEntity(account, authenticatedDomain: authBox.domain), suggestedBecause: nil)
                    accountModels[account.id] = model
                    return .account(model)
                }
            } else if let hashtag = item.hashtag {
                if let existing = hashtagModels[hashtag.uniqueID] {
                    return .hashtag(existing)
                } else {
                    let model = HashtagRowViewModel(entity: hashtag)
                    hashtagModels[hashtag.uniqueID] = model
                    return .hashtag(model)
                }
            } else {
                return nil
            }
        })
    }
    
    public func didSelectSearchResult(_ authBox: MastodonAuthenticationBox, account: Mastodon.Entity.Account?, hashtag: Mastodon.Entity.Tag?) {
        let historyItem = Persistence.SearchHistory.Item(updatedAt: .now, userID: authBox.userID, account: account, hashtag: hashtag)
        try? FileManager.default.addSearchItem(historyItem, for: authBox)
        updateHistory(authBox)
    }
}

public enum SearchScope: CaseIterable {
    case all
    case people
    case hashtags
    case posts
    
    var searchType: Mastodon.API.V2.Search.SearchType {
        switch self {
        case .all:          return .default
        case .people:       return .accounts
        case .hashtags:     return .hashtags
        case .posts:        return .statuses
        }
    }
}
