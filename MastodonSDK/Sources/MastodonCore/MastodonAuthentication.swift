// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

public struct MastodonAuthentication: Codable, Hashable {
    public typealias ID = UUID
    
    public private(set) var identifier: ID
    public private(set) var domain: String
    public private(set) var username: String

    public private(set) var appAccessToken: String
    public private(set) var userAccessToken: String
    public private(set) var clientID: String
    public private(set) var clientSecret: String
    
    public private(set) var createdAt: Date
    public private(set) var updatedAt: Date
    public private(set) var activedAt: Date

    public private(set) var userID: String
    
    public private(set) var instance: Mastodon.Entity.Instance?
    public private(set) var instanceV2: Mastodon.Entity.V2.Instance?
    
    internal var persistenceIdentifier: String {
        "\(username)@\(domain)"
    }
    
    public static func createFrom(
        domain: String,
        userID: String,
        username: String,
        appAccessToken: String,
        userAccessToken: String,
        clientID: String,
        clientSecret: String,
        instance: Mastodon.Entity.Instance?,
        instanceV2: Mastodon.Entity.V2.Instance?
    ) -> Self {
        let now = Date()
        return MastodonAuthentication(
            identifier: .init(),
            domain: domain,
            username: username,
            appAccessToken: appAccessToken,
            userAccessToken: userAccessToken,
            clientID: clientID,
            clientSecret: clientSecret,
            createdAt: now,
            updatedAt: now,
            activedAt: now,
            userID: userID,
            instance: instance,
            instanceV2: instanceV2
        )
    }
    
    func copy(
        identifier: ID? = nil,
        domain: String? = nil,
        username: String? = nil,
        appAccessToken: String? = nil,
        userAccessToken: String? = nil,
        clientID: String? = nil,
        clientSecret: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        activedAt: Date? = nil,
        userID: String? = nil,
        instance: Mastodon.Entity.Instance? = nil,
        instanceV2: Mastodon.Entity.V2.Instance? = nil
    ) -> Self {
        MastodonAuthentication(
            identifier: identifier ?? self.identifier,
            domain: domain ?? self.domain,
            username: username ?? self.username,
            appAccessToken: appAccessToken ?? self.appAccessToken,
            userAccessToken: userAccessToken ?? self.userAccessToken,
            clientID: clientID ?? self.clientID,
            clientSecret: clientSecret ?? self.clientSecret,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            activedAt: activedAt ?? self.activedAt,
            userID: userID ?? self.userID,
            instance: instance,
            instanceV2: instanceV2
        )
    }

    func updating(instance: Mastodon.Entity.Instance) -> Self {
        copy(instance: instance)
    }

    func updating(instanceV2: Mastodon.Entity.V2.Instance) -> Self {
        copy(instanceV2: instanceV2)
    }
    
    func updating(activatedAt: Date) -> Self {
        copy(activedAt: activatedAt)
    }
    
    public func me() async throws -> Mastodon.Entity.Account {
        try await Mastodon.API.Account.lookupAccount(
            session: .shared, domain: domain,
            query: .init(acct: userID),
            authorization: Mastodon.API.OAuth.Authorization(accessToken: userAccessToken)
        ).singleOutput().value
    }
}
