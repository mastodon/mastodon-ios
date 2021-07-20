//
//  APIService+HashtagTimeline.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import MastodonSDK

extension APIService {
    
    func hashtagTimeline(
        domain: String,
        sinceID: Mastodon.Entity.Status.ID? = nil,
        maxID: Mastodon.Entity.Status.ID? = nil,
        limit: Int = onceRequestStatusMaxCount,
        local: Bool? = nil,
        hashtag: String,
        authorizationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> {
        let authorization = authorizationBox.userAuthorization
        let requestMastodonUserID = authorizationBox.userID
        let query = Mastodon.API.Timeline.HashtagTimelineQuery(
            maxID: maxID,
            sinceID: sinceID,
            minID: nil,     // prefer sinceID
            limit: limit,
            local: local,
            onlyMedia: false
        )
        
        return Mastodon.API.Timeline.hashtag(
            session: session,
            domain: domain,
            query: query,
            hashtag: hashtag,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> in
            return APIService.Persist.persistStatus(
                managedObjectContext: self.backgroundManagedObjectContext,
                domain: domain,
                query: query,
                response: response,
                persistType: .lookUp,
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

