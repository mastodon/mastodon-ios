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
        provider: UIViewController,
        tag: Mastodon.Entity.Tag
    ) async {
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
        guard let coordinator = provider.sceneCoordinator else { return }
        _ = coordinator.present(
            scene: .hashtagTimeline(tag),
            from: provider,
            transition: .show
        )
    }
}
