// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization

struct DiscoveryFeedsView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @State var selectedView: DiscoveryType = .posts
    @State var viewModel = DiscoveryFeedsViewModel()
    
    var body: some View {
       
        let timelineModel = viewModel.timelineModel(selectedView, navigator: navigator)
            TimelineListView()
            .timelineEnvironment(timelineModel: timelineModel, contentConcealModel: .alwaysShow, filter: timelineModel.timelineQueryFilter, asyncRefreshModel: viewModel.asyncRefreshModel(selectedView))
            .toolbar {
                ToolbarItem(placement: .title) {
                    Picker("Feed", selection: $selectedView) {
                        Text(L10n.Scene.Discovery.Tabs.posts)
                            .tag(DiscoveryType.posts)
                        Text(L10n.Scene.Discovery.Tabs.hashtags)
                            .tag(DiscoveryType.hashtags)
                        Text(L10n.Scene.Discovery.Tabs.news)
                            .tag(DiscoveryType.news)
                        Text(L10n.Scene.Discovery.Tabs.forYou)
                            .tag(DiscoveryType.forYou)
                    }
                    .pickerStyle(.segmented)
                }
            }
    }
}

@MainActor
@Observable class DiscoveryFeedsViewModel {
    // create the requested timelineviewmodel lazily and keep it in case we switch back
    private var timelineModels = [DiscoveryType : TimelineListViewModel]()
    private var asyncRefreshModels = [DiscoveryType : AsyncRefreshViewModel]()
    
    func timelineModel(_ discoveryType: DiscoveryType, navigator: MastodonNavigationRouter) -> TimelineListViewModel {
        if let existing = timelineModels[discoveryType] {
            return existing
        } else {
            
            let model = TimelineListViewModel(timeline: .discover(discoveryType), navigator: navigator, asyncRefreshViewModel: asyncRefreshModel(discoveryType))
            timelineModels[discoveryType] = model
            return model
        }
    }
    
    func asyncRefreshModel(_ discoveryType: DiscoveryType) -> AsyncRefreshViewModel {
        if let existing = asyncRefreshModels[discoveryType] {
            return existing
        } else {
            let model = AsyncRefreshViewModel()
            asyncRefreshModels[discoveryType] = model
            return model
        }
    }
}
