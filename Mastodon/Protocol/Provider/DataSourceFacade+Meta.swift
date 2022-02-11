//
//  DataSourceFacade+Meta.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import Foundation
import CoreDataStack
import MetaTextKit

extension DataSourceFacade {
    
    static func responseToMetaTextAction(
        provider: DataSourceProvider,
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
        provider: DataSourceProvider,
        status: ManagedObjectRecord<Status>,
        meta: Meta
    ) async {
        switch meta {
        case .url(_, _, let url, _),
             .mention(_, let url, _) where url.lowercased().hasPrefix("http"):
            // note:
            // some server mark the normal url as "u-url" class. highlighted content is a URL
            guard let url = URL(string: url) else { return }
            if let domain = provider.context.authenticationService.activeMastodonAuthenticationBox.value?.domain, url.host == domain,
               url.pathComponents.count >= 4,
               url.pathComponents[0] == "/",
               url.pathComponents[1] == "web",
               url.pathComponents[2] == "statuses" {
                let statusID = url.pathComponents[3]
                let threadViewModel = RemoteThreadViewModel(context: provider.context, statusID: statusID)
                await provider.coordinator.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
            } else {
                await provider.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
            }
        case .hashtag(_, let hashtag, _):
            let hashtagTimelineViewModel = HashtagTimelineViewModel(context: provider.context, hashtag: hashtag)
            await provider.coordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel), from: provider, transition: .show)
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
