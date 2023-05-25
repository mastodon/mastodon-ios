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
    public let inMemoryCache: MastodonAccountInMemoryCache

    public init(
        authenticationRecord: ManagedObjectRecord<MastodonAuthentication>,
        domain: String,
        userID: MastodonUser.ID,
        appAuthorization: Mastodon.API.OAuth.Authorization,
        userAuthorization: Mastodon.API.OAuth.Authorization,
        inMemoryCache: MastodonAccountInMemoryCache
    ) {
        self.authenticationRecord = authenticationRecord
        self.domain = domain
        self.userID = userID
        self.appAuthorization = appAuthorization
        self.userAuthorization = userAuthorization
        self.inMemoryCache = inMemoryCache
    }
}

extension MastodonAuthenticationBox {
    
    init(authentication: MastodonAuthentication) {
        self = MastodonAuthenticationBox(
            authenticationRecord: .init(objectID: authentication.objectID),
            domain: authentication.domain,
            userID: authentication.userID,
            appAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.appAccessToken),
            userAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken),
            inMemoryCache: .sharedCache(for: authentication.objectID.description)
        )
    }
    
}

public class MastodonAccountInMemoryCache {
    @Published public var followingUserIds: [String] = []
    @Published public var blockedUserIds: [String] = []
    @Published public var followRequestedUserIDs: [String] = []
    
    static var sharedCaches = [String: MastodonAccountInMemoryCache]()
    
    public static func sharedCache(for key: String) -> MastodonAccountInMemoryCache {
        if let sharedCache = sharedCaches[key] {
            return sharedCache
        }
        
        let sharedCache = MastodonAccountInMemoryCache()
        sharedCaches[key] = sharedCache
        return sharedCache
    }
}
