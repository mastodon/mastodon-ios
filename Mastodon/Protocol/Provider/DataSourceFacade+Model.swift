//
//  DataSourceFacade+Model.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import Foundation
import MastodonUI
import MastodonSDK

extension DataSourceFacade {
    static func status(
        status: Mastodon.Entity.Status,
        target: StatusTarget
    ) -> Mastodon.Entity.Status? {
        switch target {
        case .status:
            return status.reblog ?? status
        case .reblog:
            return status
        }
    }
}

extension DataSourceFacade {
    static func author(
        status: Mastodon.Entity.Status,
        target: StatusTarget
    ) -> Mastodon.Entity.Account? {
        DataSourceFacade.status(status: status, target: target)
            .flatMap { $0.account }
    }
}
