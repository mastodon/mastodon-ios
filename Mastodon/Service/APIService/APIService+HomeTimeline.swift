//
//  APIService+HomeTimeline.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import MastodonSDK

extension APIService {
    
    func homeTimeline(
        domain: String,
        sinceID: Mastodon.Entity.Status.ID? = nil,
        maxID: Mastodon.Entity.Status.ID? = nil,
        limit: Int = 100,
        local: Bool? = nil,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> {
        let authorization = authorizationBox.userAuthorization
        let requestMastodonUserID = authorizationBox.userID
        let query = Mastodon.API.Timeline.HomeTimelineQuery(
            maxID: maxID,
            sinceID: sinceID,
            minID: nil,     // prefer sinceID
            limit: limit,
            local: local
        )
        
        return Mastodon.API.Timeline.home(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> in
            return APIService.Persist.persistTimeline(
                managedObjectContext: self.backgroundManagedObjectContext,
                domain: domain,
                query: query,
                response: response,
                persistType: .home,
                requestMastodonUserID: requestMastodonUserID,
                log: OSLog.api
            )
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Status]> in
                switch result {
                case .success:
                    return response
                case .failure(let error):
                    throw error
                }
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
}
