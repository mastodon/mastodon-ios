//
//  µ.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public extension Foundation.Notification.Name {
    static let userFetched = Notification.Name(rawValue: "org.joinmastodon.app.user-fetched")
}

extension APIService {
    
    public func homeTimeline(
        sinceID: Mastodon.Entity.Status.ID? = nil,
        maxID: Mastodon.Entity.Status.ID? = nil,
        limit: Int = onceRequestStatusMaxCount,
        local: Bool? = nil,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        let query = Mastodon.API.Timeline.HomeTimelineQuery(
            maxID: maxID,
            sinceID: sinceID,
            minID: nil,     // prefer sinceID
            limit: limit,
            local: local
        )
        
        let response = try await Mastodon.API.Timeline.home(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext

        // FIXME: This is a dirty hack to make the performance-stuff work.
        // Problem is, that we don't persist the user on disk anymore. So we have to fetch
        // it when we need it to display on the home timeline.
        for authentication in AuthenticationServiceProvider.shared.authentications {
            _ = try await accountInfo(domain: authentication.domain,
                                       userID: authentication.userID,
                                       authorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)).value
        }

        NotificationCenter.default.post(name: .userFetched, object: nil)

        return response
    }
    
}
