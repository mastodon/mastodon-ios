//
//  APIService+PublicTimeline.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-29.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
 
    public func publicTimeline(
        query: Mastodon.API.Timeline.PublicTimelineQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Timeline.public(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()

        return response
    }   // end func
    
}
