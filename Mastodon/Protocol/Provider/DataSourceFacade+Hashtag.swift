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
        provider: DataSourceProvider & AuthContextProvider,
        tag: DataSourceItem.TagKind
    ) async {
        switch tag {
        case .entity(let entity):
            await coordinateToHashtagScene(provider: provider, tag: entity)
        case .record(let record):
            await coordinateToHashtagScene(provider: provider, tag: record)
        }
    }
    
    @MainActor
    static func coordinateToHashtagScene(
        provider: DataSourceProvider & AuthContextProvider,
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
    
    @MainActor
    static func coordinateToHashtagScene(
        provider: DataSourceProvider & AuthContextProvider,
        tag: ManagedObjectRecord<Tag>
    ) async {
        let managedObjectContext = provider.context.managedObjectContext
        let _name: String? = try? await managedObjectContext.perform {
            guard let tag = tag.object(in: managedObjectContext) else { return nil }
            return tag.name
        }
        
        guard let name = _name else { return }
        
        let hashtagTimelineViewModel = HashtagTimelineViewModel(
            context: provider.context,
            authContext: provider.authContext,
            hashtag: name
        )
        
        _ = provider.coordinator.present(
            scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
            from: provider,
            transition: .show
        )
    }
}
