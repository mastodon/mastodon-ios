//
//  MastodonAuthenticationBox.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-20.
//

import Foundation
import CoreDataStack
import MastodonSDK

public protocol AuthContextProvider {
    var authenticationBox: MastodonAuthenticationBox { get }
}

public struct MastodonAuthenticationBox: UserIdentifier {
    public let authentication: MastodonAuthentication
    public var domain: String { authentication.domain }
    public var userID: String { authentication.userID }
    public var appAuthorization: Mastodon.API.OAuth.Authorization {
        Mastodon.API.OAuth.Authorization(accessToken: authentication.appAccessToken)
    }
    public var userAuthorization: Mastodon.API.OAuth.Authorization {
        Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
    }
    
    public init(authentication: MastodonAuthentication) {
        self.authentication = authentication
    }
    
    @MainActor
    public var cachedAccount: Mastodon.Entity.Account? {
        return authentication.cachedAccount()
    }
}
