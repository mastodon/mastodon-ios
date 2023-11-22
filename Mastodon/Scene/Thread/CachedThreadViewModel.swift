//
//  CachedThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import Foundation
import MastodonSDK
import MastodonCore

final class CachedThreadViewModel: ThreadViewModel {
    init(context: AppContext, authContext: AuthContext, status: MastodonStatus) {
        let threadContext = StatusItem.Thread.Context(status: status)
        super.init(
            context: context,
            authContext: authContext,
            optionalRoot: .root(context: threadContext)
        )
    }
}
