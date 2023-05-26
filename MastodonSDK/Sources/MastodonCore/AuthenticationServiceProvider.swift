// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Combine
import CoreDataStack
import MastodonSDK
import KeychainAccess
import MastodonCommon

public class AuthenticationServiceProvider: ObservableObject {
    public static let shared = AuthenticationServiceProvider()
    private static let keychain = Keychain(service: "org.joinmastodon.app.authentications", accessGroup: AppName.groupID)

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
    
    func sortByActivation() { // fixme: why do we need this?
        authentications = authentications.sorted(by: { $0.activedAt > $1.activedAt })
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
}

// MARK: - Private
private extension AuthenticationServiceProvider {
    func persist() {
        for authentication in authentications {
            Self.keychain[authentication.persistenceIdentifier] = try? JSONEncoder().encode(authentication).base64EncodedString()
        }
    }
}
