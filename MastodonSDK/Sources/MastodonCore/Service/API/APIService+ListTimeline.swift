import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    public func listTimeline(
        id: String,
        query: Mastodon.API.Timeline.PublicTimelineQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Timeline.list(
            session: session,
            domain: domain,
            query: query,
            id: id,
            authorization: authorization
        )

        return response
    }
}

extension APIService {
    public func addAccountToList(
        listID: Mastodon.Entity.List.ID,
        accountID: Mastodon.Entity.Account.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        try await Mastodon.API.Lists.addAccountToList(
            listId: listID,
            accountID: accountID,
            session: session,
            domain: authenticationBox.domain,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
    }
    
    public func removeAccountFromList(
        listID: Mastodon.Entity.List.ID,
        accountID: Mastodon.Entity.Account.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        try await Mastodon.API.Lists.deleteAccountFromList(
            listId: listID,
            accountID: accountID,
            session: session,
            domain: authenticationBox.domain,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
    }
}
