// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore

struct ExploreRootView: View {
    var sceneCoordinator: SceneCoordinator?
    @Environment(MastodonNavigationRouter.self) var navigationStackNavigator
    @Environment(SearchModel.self) var searchModel
    
    var body: some View {
        @Bindable var searchModel = searchModel
        contents
            .searchable(text: $searchModel.searchText, isPresented: $searchModel.isSearchActive)
    }
    
    @ViewBuilder var contents: some View {
        if !searchModel.searchText.isEmpty || (searchModel.isSearchActive && !searchModel.searchHistory.isEmpty) {
            if searchModel.searchText.isEmpty {
                searchHistory
            } else {
                VStack {
                    Text("Searching...")
                        .font(.title)
                    Text(searchModel.searchText)
                }
            }
        } else {
            DiscoveryFeedsView()
                .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                    navigationStackNavigator.destinationView(destination, sceneCoordinator: sceneCoordinator)
                }
                .environment(NestedScrollInteractionViewModel())
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
    private let user: String
    
    var searchText = ""
    var isSearchActive: Bool = false
    var searchHistory: [TimelineItem] = []
    
    var accountModels = [ Mastodon.Entity.Account.ID : AccountRowViewModel]()
    var hashtagModels = [ String : HashtagRowViewModel ]()
    
    init(authenticationBox: MastodonAuthenticationBox?) {
        if let authenticationBox {
            user = authenticationBox.globallyUniqueUserIdentifier
            let historyItems = (try? FileManager.default.searchItems(for: authenticationBox)) ?? []
            searchHistory = historyItems.compactMap({ item -> TimelineItem? in
                if let account = item.account {
                    if let existing = accountModels[account.id] {
                        return .account(existing)
                    } else {
                        let model = AccountRowViewModel(account: MastodonAccount.fromEntity(account, authenticatedDomain: authenticationBox.domain), suggestedBecause: nil)
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
        } else {
            user = "NONE"
        }
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
