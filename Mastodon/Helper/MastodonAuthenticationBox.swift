//
//  MastodonAuthenticationBox.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-20.
//

import Foundation
import CoreDataStack
import MastodonSDK
import MastodonUI

struct MastodonAuthenticationBox: UserIdentifier {
    let authenticationRecord: ManagedObjectRecord<MastodonAuthentication>
    let domain: String
    let userID: MastodonUser.ID
    let appAuthorization: Mastodon.API.OAuth.Authorization
    let userAuthorization: Mastodon.API.OAuth.Authorization
}
