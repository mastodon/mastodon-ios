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
        ).singleOutput()

        return response
    }
}
