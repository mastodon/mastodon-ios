// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonAsset
import MastodonLocalization

struct ExploreRootView: View {
    @Environment(MastodonNavigationRouter.self) var navigationStackNavigator
    @Environment(SearchViewModel.self) var searchViewModel
    
    @State var searchQueryModel = SearchQueryModel()
    
    @State var searchTimelineModel: TimelineListViewModel?
    @State var asyncRefreshModel = AsyncRefreshViewModel()
    
    @State var peopleQueryModel = SearchQueryModel(scope: .people)
    @State var hashtagsQueryModel = SearchQueryModel(scope: .hashtags)
    @State var postsQueryModel = SearchQueryModel(scope: .posts)
    
    var body: some View {
        @Bindable var searchViewModel = searchViewModel
        contents
            .toolbarTitleDisplayMode(.inline)
            .searchable(text: $searchViewModel.searchText, tokens: $searchViewModel.searchTokens, isPresented: $searchViewModel.isSearchActive) { item in
                Text(item.searchHistoryString ?? "")
            }
            .searchSuggestions {
                if searchViewModel.searchText.isEmpty {
                    searchHistorySuggestions
                }
            }
            .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                navigationStackNavigator.destinationView(destination, sceneCoordinator: nil)
            }
            .task(id: searchViewModel.searchText) {
                if searchTimelineModel == nil {
                    searchTimelineModel = TimelineListViewModel(timeline: .search(searchQueryModel), navigator: navigationStackNavigator, asyncRefreshViewModel: asyncRefreshModel)
                }
                for queryModel in [searchQueryModel, peopleQueryModel, hashtagsQueryModel, postsQueryModel] {
                    queryModel.trimmedSearchString = searchViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard searchQueryModel.trimmedSearchString.count > 2 else { return }
                await searchTimelineModel?.reload()
            }
            .onChange(of: searchViewModel.searchTokens, { _, newValue in
                guard let chosenItem = newValue.first else { return }
                switch chosenItem {
                case .account(let model):
                    navigationStackNavigator.push(.profile(account: model.account._legacyEntity, relationship: model.myRelationship))
                case .hashtag(let model):
                    navigationStackNavigator.push(.timeline(.hashtag(model.entity, includeHeader: true)))
                default:
                    break
                }
            })
            .onChange(of: navigationStackNavigator.navigationPath) { oldValue, newValue in
                // record this as a recent search if appropriate
                let isNavigatingFromSearchScreen = oldValue.isEmpty
                let selectedToken = searchViewModel.searchTokens.first
                searchViewModel.searchTokens.removeAll()
                let searchIsShowingNewResults = !searchViewModel.searchText.isEmpty
                guard isNavigatingFromSearchScreen, selectedToken != nil || searchIsShowingNewResults, let authenticatedUser = AuthenticationObserver.shared.currentActiveUser else { return }
                switch newValue.first {
                case .profile(let account, _):
                    searchViewModel.didSelectSearchResult(authenticatedUser, account: account, hashtag: nil)
                case .timeline(.hashtag(let tag, _)):
                    searchViewModel.didSelectSearchResult(authenticatedUser, account: nil, hashtag: tag)
                default:
                    break
                }
            }
    }
    
    @ViewBuilder var contents: some View {
        if !searchViewModel.searchText.isEmpty {
            GeometryReader { geo in
                let useableWidth = min(maxFeedContentWidth, geo.size.width)
                if let searchTimelineModel, searchTimelineModel.currentDisplaySlice.contains(where: { $0.isRealItem }) {
                    TimelineListView()
                        .timelineEnvironment(timelineModel: searchTimelineModel, contentConcealModel: .alwaysShow, filter: searchTimelineModel.timeline.filterModel, asyncRefreshModel: asyncRefreshModel)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach([SearchScope.people, .hashtags, .posts], id: \.self) { scope in
                            let rowModel = {
                                switch scope {
                                case .people:
                                    peopleQueryModel
                                case .hashtags:
                                    hashtagsQueryModel
                                case .posts:
                                    postsQueryModel
                                case .all:
                                    searchQueryModel
                                }
                            }()
                            ScopedSearchResultsRowView(useableWidth: useableWidth)
                                .environment(rowModel)
                                .onTapGesture {
                                    navigationStackNavigator.push(.timeline(.search(SearchQueryModel(scope: scope, trimmedSearchString: searchQueryModel.trimmedSearchString))))
                                }
                        }
                    }
                }
            }
        } else {
            DiscoveryFeedsView()
        }
    }
    
    @ViewBuilder var searchHistorySuggestions: some View {
        ForEach(searchViewModel.searchHistory, id: \.mastodonID) { item in
            Text(item.searchHistoryString ?? "")
                .searchCompletion(item)
        }
    }
}

@MainActor
@Observable class SearchViewModel {
    var searchText = ""
    var isSearchActive: Bool = false
    var searchHistory: [TimelineItem] = []
    var searchTokens: [TimelineItem] = []
    
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

public struct ScopedSearchResultsRowView: View {
    let useableWidth: CGFloat
    @Environment(SearchQueryModel.self) var queryModel
    
    public var body: some View {
        let text = {
            switch queryModel.scope {
            case .hashtags: L10nLookup.Scene.Search.searchForHashtags(matching: queryModel.trimmedSearchString)
            case .people:
                L10nLookup.Scene.Search.searchForPeople(matching: queryModel.trimmedSearchString)
            case .posts:
                L10nLookup.Scene.Search.searchForPosts(matching: queryModel.trimmedSearchString)
            case .all:
                "UNEXPECTED"
            }
        }()
        
        HStack {
            Text(text)
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.accent.swiftUIColor)
            Spacer()
            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
        }
        .padding()
        .padding(.bottom, doublePadding)
        .frame(width: useableWidth, alignment: .leading)
        .contentShape(Rectangle())
    }
}

extension TimelineItem {
    @MainActor
    var searchHistoryString: String? {
        switch self {
        case .account(let model):
            "@\(model.account.displayInfo.fullHandle)"
        case .hashtag(let model):
            "#\(model.entity.name)"
        default:
            nil
        }
    }
}
