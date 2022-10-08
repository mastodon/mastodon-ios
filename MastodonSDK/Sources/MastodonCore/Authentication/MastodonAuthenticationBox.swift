//
//  MastodonAuthenticationBox.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-20.
//

import Foundation
import CoreDataStack
import MastodonSDK

public struct MastodonAuthenticationBox: UserIdentifier {
    public let authenticationRecord: ManagedObjectRecord<MastodonAuthentication>
    public let domain: String
    public let userID: MastodonUser.ID
    public let appAuthorization: Mastodon.API.OAuth.Authorization
    public let userAuthorization: Mastodon.API.OAuth.Authorization
    
    public init(
        authenticationRecord: ManagedObjectRecord<MastodonAuthentication>,
        domain: String,
        userID: MastodonUser.ID,
        appAuthorization: Mastodon.API.OAuth.Authorization,
        userAuthorization: Mastodon.API.OAuth.Authorization
    ) {
        self.authenticationRecord = authenticationRecord
        self.domain = domain
        self.userID = userID
        self.appAuthorization = appAuthorization
        self.userAuthorization = userAuthorization
    }
}

extension MastodonAuthenticationBox {
    
    init(authentication: MastodonAuthentication) {
        self = MastodonAuthenticationBox(
            authenticationRecord: .init(objectID: authentication.objectID),
            domain: authentication.domain,
            userID: authentication.userID,
            appAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.appAccessToken),
            userAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
        )
    }
    
}
