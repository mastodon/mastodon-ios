//
//  APIService+PublicTimeline.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import DateToolsSwift
import MastodonSDK

extension APIService {
    
    static let publicTimelineRequestWindowInSec: TimeInterval = 15 * 60
    
    func publicTimeline(
        count: Int = 20,
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Toot]>, Error> {
                
        return Mastodon.API.Timeline.public(
            session: session,
            domain: domain,
            query: Mastodon.API.Timeline.PublicTimelineQuery()
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Toot]>, Error> in
            return APIService.Persist.persistTimeline(
                domain: domain,
                managedObjectContext: self.backgroundManagedObjectContext,
                response: response,
                persistType: Persist.PersistTimelineType.publicHomeTimeline
            )
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Toot]> in
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
