// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack
import MastodonSDK

public struct MastodonAuthentication: Codable, Hashable, UserIdentifier {
    public enum InstanceConfiguration: Codable, Hashable {
        case v1(Mastodon.Entity.Instance)
        case v2(Mastodon.Entity.V2.Instance, TranslationLanguages)
        
        public func canTranslateFrom(_ sourceLocale: String, to targetLanguage: String) -> Bool {
            switch self {
            case .v1:
                return false
            case let .v2(instance, translationLanguages):
                guard instance.configuration?.translation?.enabled == true else { return false }
                return translationLanguages[sourceLocale]?.contains(targetLanguage) == true
            }
        }
    }
    
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
    public private(set) var instanceObjectIdURI: URL?
    public private(set) var instanceConfiguration: InstanceConfiguration?
    
    public var persistenceIdentifier: String {
        "\(username)@\(domain)"
    }
    
    public static func createFrom(
        domain: String,
        userID: String,
        username: String,
        appAccessToken: String,
        userAccessToken: String,
        clientID: String,
        clientSecret: String
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
            instanceObjectIdURI: nil,
            instanceConfiguration: nil
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
        instanceObjectIdURI: URL? = nil,
        instanceConfiguration: InstanceConfiguration? = nil
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
            instanceObjectIdURI: instanceObjectIdURI ?? self.instanceObjectIdURI,
            instanceConfiguration: instanceConfiguration ?? self.instanceConfiguration
        )
    }
    
    public func instance(in context: NSManagedObjectContext) -> Instance? {
        guard let instanceObjectIdURI,
              let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: instanceObjectIdURI)
        else {
            return nil
        }

        let instance = try? context.existingObject(with: objectID) as? Instance
        return instance
    }
    
    public func user(in context: NSManagedObjectContext) -> MastodonUser? {
        let userPredicate = MastodonUser.predicate(domain: domain, id: userID)
        return MastodonUser.findOrFetch(in: context, matching: userPredicate)
    }

    public func account() -> Mastodon.Entity.Account? {

        let account = FileManager
            .default
            .accounts(for: self.userIdentifier())
            .first(where: { $0.id == userID })

        return account
    }

    public func userIdentifier() -> MastodonUserIdentifier {
        MastodonUserIdentifier(domain: domain, userID: userID)
    }

    func updating(instance: Instance) -> Self {
        copy(instanceObjectIdURI: instance.objectID.uriRepresentation())
    }
    
    func updating(instanceV1 instance: Mastodon.Entity.Instance) -> Self {
        return copy(instanceConfiguration: .v1(instance))
    }
    
    func updating(instanceV2 instance: Mastodon.Entity.V2.Instance) -> Self {
        guard
            let instanceConfiguration = self.instanceConfiguration,
            case let InstanceConfiguration.v2(_, translationLanguages) = instanceConfiguration
        else {
            return copy(instanceConfiguration: .v2(instance, [:]))
        }
        return copy(instanceConfiguration: .v2(instance, translationLanguages))
    }
    
    func updating(translationLanguages: TranslationLanguages) -> Self {
        switch self.instanceConfiguration {
        case .v1(let instance):
            return copy(instanceConfiguration: .v1(instance))
        case .v2(let instance, _):
            return copy(instanceConfiguration: .v2(instance, translationLanguages))
        case .none:
            return self
        }
    }
    
    func updating(activatedAt: Date) -> Self {
        copy(activedAt: activatedAt)
    }

    var authorization: Mastodon.API.OAuth.Authorization {
        .init(accessToken: userAccessToken)
    }
}
