//
//  DataSourceFacade+Hashtag.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit
import CoreDataStack
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    @MainActor
    static func coordinateToHashtagScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        tag: Mastodon.Entity.Tag
    ) async {
        let hashtagTimelineViewModel = HashtagTimelineViewModel(
            context: provider.context,
            authContext: provider.authContext,
            hashtag: tag.name
        )
        
        _ = provider.coordinator.present(
            scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
            from: provider,
            transition: .show
        )
    }
}
