// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK
import MastodonLocalization

enum AboutInstanceSection: Int, Hashable {
    case main = 0

    var title: String {
        return L10n.Scene.Settings.ServerDetails.AboutInstance.title
    }
}

enum AboutInstanceItem: Hashable {
    case adminAccount(Mastodon.Entity.Account)
    case contactAdmin(String)
}
