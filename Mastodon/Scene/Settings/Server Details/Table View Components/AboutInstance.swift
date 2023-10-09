// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

enum AboutInstanceSection: Hashable {
    case main
}

enum AboutInstanceItem: Hashable {
    case adminAccount(Mastodon.Entity.Account)
    case contactAdmin(String)
}
