//
//  DataSourceFacade+URL.swift
//  Mastodon
//
//  Created by Kyle Bashour on 11/24/22.
//

import Foundation
import CoreDataStack
import MetaTextKit
import MastodonCore

extension DataSourceFacade {
    static func responseToURLAction(
        provider: DataSourceProvider & AuthContextProvider,
        status: ManagedObjectRecord<Status>,
        url: URL
    ) async {
        let domain = provider.authContext.mastodonAuthenticationBox.domain
        if url.host == domain,
           url.pathComponents.count >= 4,
           url.pathComponents[0] == "/",
           url.pathComponents[1] == "web",
           url.pathComponents[2] == "statuses" {
            let statusID = url.pathComponents[3]
            let threadViewModel = RemoteThreadViewModel(context: provider.context, authContext: provider.authContext, statusID: statusID)
            _ = await provider.coordinator.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
        } else {
            _ = await provider.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        }
    }
}
