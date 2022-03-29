//
//  DataSourceFacade+Hashtag.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit
import CoreDataStack
import MastodonSDK

extension DataSourceFacade {
    @MainActor
    static func coordinateToHashtagScene(
        provider: DataSourceProvider,
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
        provider: DataSourceProvider,
        tag: Mastodon.Entity.Tag
    ) async {
        let hashtagTimelineViewModel = HashtagTimelineViewModel(
            context: provider.context,
            hashtag: tag.name
        )
        
        provider.coordinator.present(
            scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
            from: provider,
            transition: .show
        )
    }
    
    @MainActor
    static func coordinateToHashtagScene(
        provider: DataSourceProvider,
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
            hashtag: name
        )
        
        provider.coordinator.present(
            scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
            from: provider,
            transition: .show
        )
    }
}
