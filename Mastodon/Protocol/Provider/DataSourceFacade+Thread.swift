//
//  DataSourceFacade+Thread.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    static func coordinateToStatusThreadScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        target: StatusTarget,
        status: Mastodon.Entity.Status
    ) async {
        let _root: StatusItem.Thread? = {
            let _redirectRecord = DataSourceFacade.status(
                status: status,
                target: target
            )
            guard let redirectRecord = _redirectRecord else { return nil }

            let threadContext = StatusItem.Thread.Context(status: redirectRecord)
            return StatusItem.Thread.root(context: threadContext)
        }()
        guard let root = _root else {
            assertionFailure()
            return
        }
        
        await coordinateToStatusThreadScene(
            provider: provider,
            root: root
        )
    }
    
    @MainActor
    static func coordinateToStatusThreadScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        root: StatusItem.Thread
    ) async {
        let threadViewModel = ThreadViewModel(
            context: provider.context,
            authContext: provider.authContext,
            optionalRoot: root
        )
        _ = provider.coordinator.present(
            scene: .thread(viewModel: threadViewModel),
            from: provider,
            transition: .show
        )
    }
}
