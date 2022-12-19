//
//  DataSourceFacade+Meta.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import Foundation
import CoreDataStack
import MetaTextKit
import MastodonCore

extension DataSourceFacade {
    
    static func responseToMetaTextAction(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: ManagedObjectRecord<Status>,
        meta: Meta
    ) async throws {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        await responseToMetaTextAction(
            provider: provider,
            status: redirectRecord,
            meta: meta
        )
        
    }
    
    static func responseToMetaTextAction(
        provider: DataSourceProvider & AuthContextProvider,
        status: ManagedObjectRecord<Status>,
        meta: Meta
    ) async {
        switch meta {
        // note:
        // some server mark the normal url as "u-url" class. highlighted content is a URL
        case .url(_, _, let url, _),
             .mention(_, let url, _) where url.lowercased().hasPrefix("http"):
            // fix non-ascii character URL link can not open issue
            guard let url = URL(string: url) ?? URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url) else {
                assertionFailure()
                return
            }

            await responseToURLAction(
                provider: provider,
                status: status,
                url: url
            )
        case .hashtag(_, let hashtag, _):
            let hashtagTimelineViewModel = HashtagTimelineViewModel(context: provider.context, authContext: provider.authContext, hashtag: hashtag)
            _ = await provider.coordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel), from: provider, transition: .show)
        case .mention(_, let mention, let userInfo):
            await coordinateToProfileScene(
                provider: provider,
                status: status,
                mention: mention,
                userInfo: userInfo
            )
        default:
            assertionFailure()
            break
        }
    }
    
}
