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
import MastodonSDK

extension DataSourceFacade {
    
    static func responseToMetaTextAction(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: MastodonStatus,
        meta: Meta
    ) async throws {
        let redirectRecord = DataSourceFacade.status(
            status: status,
            target: target
        )
        
        await responseToMetaTextAction(
            provider: provider,
            status: redirectRecord,
            meta: meta
        )
        
    }
    
    static func responseToMetaTextAction(
        provider: DataSourceProvider & AuthContextProvider,
        status: MastodonStatus,
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
                url: url
            )
        case .hashtag(_, let hashtag, _):
            guard let coordinator = await provider.sceneCoordinator else { return }
            let tag = Mastodon.Entity.Tag(name: hashtag, url: "")
            _ = await coordinator.present(scene: .hashtagTimeline(tag), from: provider, transition: .show)
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
