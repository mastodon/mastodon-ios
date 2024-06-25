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

    @MainActor
    @discardableResult
    func updating(instanceV1 instance: Mastodon.Entity.Instance, for domain: String) -> Self {
        authentications = authentications.map { authentication in
            guard authentication.domain == domain else { return authentication }
            return authentication.updating(instanceV1: instance)
        }
        return self
    }
    
    @MainActor
    @discardableResult
    func updating(instanceV2 instance: Mastodon.Entity.V2.Instance, for domain: String) -> Self {
        authentications = authentications.map { authentication in
            guard authentication.domain == domain else { return authentication }
            return authentication.updating(instanceV2: instance)
        }
        return self
    }
    
    @MainActor
    @discardableResult
    func updating(translationLanguages: TranslationLanguages, for domain: String) -> Self {
        authentications = authentications.map { authentication in
            guard authentication.domain == domain else { return authentication }
            return authentication.updating(translationLanguages: translationLanguages)
        }
        return self
    }
    
    func delete(authentication: MastodonAuthentication) throws {
        try Self.keychain.remove(authentication.persistenceIdentifier)
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
        do {
            let legacyAuthentications = try context.fetch(MastodonAuthenticationLegacy.sortedFetchRequest)
            let migratedAuthentications = legacyAuthentications.compactMap { auth -> MastodonAuthentication? in
                return MastodonAuthentication(
                    identifier: auth.identifier,
                    domain: auth.domain,
                    username: auth.username,
                    appAccessToken: auth.appAccessToken,
                    userAccessToken: auth.userAccessToken,
                    clientID: auth.clientID,
                    clientSecret: auth.clientSecret,
                    createdAt: auth.createdAt,
                    updatedAt: auth.updatedAt,
                    activedAt: auth.activedAt,
                    userID: auth.userID
                )
            }

            if migratedAuthentications.count != legacyAuthentications.count {
                logger.log(level: .default, "Not all account authentications could be migrated.")
            } else {
                logger.log(level: .default, "All account authentications were successful.")
            }

            self.authentications = migratedAuthentications
            userDefaults.didMigrateAuthentications = true
        } catch {
            userDefaults.didMigrateAuthentications = false
            logger.log(level: .error, "Could not migrate legacy authentications")
        }
    }

    var authenticationMigrationRequired: Bool {
        userDefaults.didMigrateAuthentications == false
    }

    func fetchAccounts(apiService: APIService) async {
        // FIXME: This is a dirty hack to make the performance-stuff work.
        // Problem is, that we don't persist the user on disk anymore. So we have to fetch
        // it when we need it to display on the home timeline.
        // We need this (also) for the Account-list, but it might be the wrong place. App Startup might be more appropriate
        for authentication in authentications {
            guard let account = try? await apiService.accountInfo(domain: authentication.domain,
                                                                  userID: authentication.userID,
                                                                  authorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)).value else { continue }

            FileManager.default.store(account: account, forUserID: authentication.userIdentifier())
        }

        NotificationCenter.default.post(name: .userFetched, object: nil)
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
