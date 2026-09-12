// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Foundation
import AppIntents
import MastodonCore

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct AccountAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Account")

    @Property(title: "Name")
    var name: String?

    @Property(title: "Username")
    var username: String?

    struct AccountAppEntityQuery: EntityQuery {
        func entities(for identifiers: [AccountAppEntity.ID]) async throws -> [AccountAppEntity] {
            let wanted = Set(identifiers)
            return await MainActor.run {
                AccountAppEntity.loadFromCache().filter { wanted.contains($0.id) }
            }
        }

        func suggestedEntities() async throws -> [AccountAppEntity] {
            await MainActor.run {
                AccountAppEntity.loadFromCache()
            }
        }
    }
    static var defaultQuery = AccountAppEntityQuery()

    var id: String // if your identifier is not a String, conform the entity to EntityIdentifierConvertible.
    var displayString: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }

    init(id: String, displayString: String) {
        self.id = id
        self.displayString = displayString
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension AccountAppEntity {

    /// Ported from the legacy `Account.loadFromCache()`.
    ///
    /// `id` stays the authentication UUID string so shortcuts migrated from the
    /// legacy intent keep resolving to the same account.
    @MainActor
    static func loadFromCache() -> [AccountAppEntity] {
        AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.compactMap { authBox in
            guard let authenticatedAccount = authBox.cachedAccount else {
                return nil
            }
            let entity = AccountAppEntity(
                id: authBox.authentication.identifier.uuidString,
                displayString: authenticatedAccount.displayNameWithFallback
            )
            entity.name = authenticatedAccount.displayNameWithFallback
            entity.username = authenticatedAccount.acctWithDomain
            return entity
        }
    }

}

