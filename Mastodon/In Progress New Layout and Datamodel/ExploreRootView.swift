// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore

struct ExploreRootView: View {
    @Environment(MastodonNavigationRouter.self) var navigationStackNavigator
    @Environment(SearchViewModel.self) var searchViewModel
    
    @State var searchQueryModel = SearchQueryModel()
    
    @State var searchTimelineModel: TimelineListViewModel?
    @State var asyncRefreshModel = AsyncRefreshViewModel()
    
    var body: some View {
        @Bindable var searchViewModel = searchViewModel
        contents
            .toolbarTitleDisplayMode(.inline)
            .searchable(text: $searchViewModel.searchText, isPresented: $searchViewModel.isSearchActive)
            .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                navigationStackNavigator.destinationView(destination, sceneCoordinator: nil)
            }
            .task(id: searchViewModel.searchText) {
                if searchTimelineModel == nil {
                    searchTimelineModel = TimelineListViewModel(timeline: .search(searchQueryModel), navigator: navigationStackNavigator, asyncRefreshViewModel: asyncRefreshModel)
                }
                do { try await Task.sleep(for: .milliseconds(300)) } catch { return } // wait for a pause in typing before performing the search
                searchQueryModel.trimmedSearchString = searchViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                await searchTimelineModel?.reload()
            }
            .onChange(of: navigationStackNavigator.navigationPath) { oldValue, newValue in
                // record this as a recent search if appropriate
                let isNavigatingFromSearchScreen = oldValue.isEmpty
                let searchIsShowingNewResults = !searchViewModel.searchText.isEmpty
                guard isNavigatingFromSearchScreen, searchIsShowingNewResults, let authenticatedUser = AuthenticationObserver.shared.currentActiveUser else { return }
                switch newValue.first {
                case .profile(let account, _):
                    searchViewModel.didSelectSearchResult(authenticatedUser, account: account, hashtag: nil)
                case .timeline(.hashtag(let tag)):
                    searchViewModel.didSelectSearchResult(authenticatedUser, account: nil, hashtag: tag)
                default:
                    break
                }
            }
    }
    
    @ViewBuilder var contents: some View {
        if !searchViewModel.searchText.isEmpty || (searchViewModel.isSearchActive && !searchViewModel.searchHistory.isEmpty) {
            if searchViewModel.searchText.isEmpty {
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
                ForEach(searchViewModel.searchHistory, id: \.mastodonID) { item in
                    switch item {
                    case .account(let model):
                        AccountRowView(contentWidth: contentWidth, collectionViewModel: nil)
                            .environment(model)
                            .onTapGesture {
                                navigationStackNavigator.push(.profile(account: model.account._legacyEntity, relationship: model.myRelationship))
                            }
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
@Observable class SearchViewModel {
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
