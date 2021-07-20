//
//  MastodonAuthenticationBox.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-20.
//

import Foundation
import MastodonSDK
import CoreDataStack

struct MastodonAuthenticationBox {
    let domain: String
    let userID: MastodonUser.ID
    let appAuthorization: Mastodon.API.OAuth.Authorization
    let userAuthorization: Mastodon.API.OAuth.Authorization
}
