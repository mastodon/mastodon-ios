//
//  APIService+UserTimeline.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
 
    public func userTimeline(
        accountID: String,
        maxID: Mastodon.Entity.Status.ID? = nil,
        sinceID: Mastodon.Entity.Status.ID? = nil,
        limit: Int = onceRequestStatusMaxCount,
        excludeReplies: Bool? = nil,
        excludeReblogs: Bool? = nil,
        onlyMedia: Bool? = nil,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let query = Mastodon.API.Account.AccountStatusesQuery(
            maxID: maxID,
            sinceID: sinceID,
            excludeReplies: excludeReplies,
            excludeReblogs: excludeReblogs,
            onlyMedia: onlyMedia,
            limit: limit
        )
        
        let response = try await Mastodon.API.Account.statuses(
            session: session,
            domain: domain,
            accountID: accountID,
            query: query,
            authorization: authorization
        ).singleOutput()

        return response
    }   // end func
    
}
