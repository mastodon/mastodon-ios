// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Combine
import CoreDataStack
import MastodonSDK
import KeychainAccess
import MastodonCommon
import os.log

public class AuthenticationServiceProvider: ObservableObject {
    private let logger = Logger(subsystem: "AuthenticationServiceProvider", category: "Authentication")

    public static let shared = AuthenticationServiceProvider()
    private static let keychain = Keychain(service: "org.joinmastodon.app.authentications", accessGroup: AppName.groupID)
    private let userDefaults: UserDefaults = .shared

    private init() {}
    
    @Published public var authentications: [MastodonAuthentication] = [] {
        didSet {
            persist() // todo: Is this too heavy and too often here???
        }
    }
        
    func update(instance: Instance, where domain: String) {
        authentications = authentications.map { authentication in
            guard authentication.domain == domain else { return authentication }
            return authentication.updating(instance: instance)
        }
    }
    
    func delete(authentication: MastodonAuthentication) {
        authentications.removeAll(where: { $0 == authentication })
    }
    
    func activateAuthentication(in domain: String, for userID: String) {
        authentications = authentications.map { authentication in
            guard authentication.domain == domain, authentication.userID == userID else {
                return authentication
            }
            return authentication.updating(activatedAt: Date())
        }
    }
    
    func getAuthentication(in domain: String, for userID: String) -> MastodonAuthentication? {
        authentications.first(where: { $0.domain == domain && $0.userID == userID })
    }
}

// MARK: - Public
public extension AuthenticationServiceProvider {
    func getAuthentication(matching userAccessToken: String) -> MastodonAuthentication? {
        authentications.first(where: { $0.userAccessToken == userAccessToken })
    }
    
    func authenticationSortedByActivation() -> [MastodonAuthentication] { // fixme: why do we need this?
        return authentications.sorted(by: { $0.activedAt > $1.activedAt })
    }
        
    func restore() {
        authentications = Self.keychain.allKeys().compactMap {
            guard
                let encoded = Self.keychain[$0],
                    let data = Data(base64Encoded: encoded)
            else { return nil }
            return try? JSONDecoder().decode(MastodonAuthentication.self, from: data)
        }
    }
    
    func migrateLegacyAuthentications(in context: NSManagedObjectContext) {        
        defer { userDefaults.didMigrateAuthentications = true }
        
        do {
            let request = NSFetchRequest<NSManagedObject>(entityName: "MastodonAuthentication")
            let legacyAuthentications = try context.fetch(request)
            
            self.authentications = legacyAuthentications.compactMap { auth -> MastodonAuthentication? in
                guard
                    let identifier = auth.value(forKey: "identifier") as? UUID,
                    let domain = auth.value(forKey: "domain") as? String,
                    let username = auth.value(forKey: "username") as? String,
                    let appAccessToken = auth.value(forKey: "appAccessToken") as? String,
                    let userAccessToken = auth.value(forKey: "userAccessToken") as? String,
                    let clientID = auth.value(forKey: "clientID") as? String,
                    let clientSecret = auth.value(forKey: "clientSecret") as? String,
                    let createdAt = auth.value(forKey: "createdAt") as? Date,
                    let updatedAt = auth.value(forKey: "updatedAt") as? Date,
                    let activedAt = auth.value(forKey: "activedAt") as? Date,
                    let userID = auth.value(forKey: "userID") as? String

                else {
                    return nil
                }
                return MastodonAuthentication(
                    identifier: identifier,
                    domain: domain,
                    username: username,
                    appAccessToken: appAccessToken,
                    userAccessToken: userAccessToken,
                    clientID: clientID,
                    clientSecret: clientSecret,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    activedAt: activedAt,
                    userID: userID
                )
            }
        } catch {
            logger.log(level: .error, "Could not migrate legacy authentications")
        }
    }
    
    var authenticationMigrationRequired: Bool {
        !userDefaults.didMigrateAuthentications
    }
}

// MARK: - Private
private extension AuthenticationServiceProvider {
    func persist() {
        for authentication in authentications {
            Self.keychain[authentication.persistenceIdentifier] = try? JSONEncoder().encode(authentication).base64EncodedString()
        }
    }
}
