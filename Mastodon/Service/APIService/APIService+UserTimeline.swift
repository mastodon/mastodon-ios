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
import CommonOSLog
import MastodonSDK

extension APIService {
 
    func userTimeline(
        domain: String,
        accountID: String,
        maxID: Mastodon.Entity.Status.ID? = nil,
        sinceID: Mastodon.Entity.Status.ID? = nil,
        limit: Int = onceRequestStatusMaxCount,
        excludeReplies: Bool? = nil,
        excludeReblogs: Bool? = nil,
        onlyMedia: Bool? = nil,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> {
        let authorization = authorizationBox.userAuthorization
        let requestMastodonUserID = authorizationBox.userID
        let query = Mastodon.API.Account.AccountStatuseseQuery(
            maxID: maxID,
            sinceID: sinceID,
            excludeReplies: excludeReplies,
            excludeReblogs: excludeReblogs,
            onlyMedia: onlyMedia,
            limit: limit
        )
        
        return Mastodon.API.Account.statuses(
            session: session,
            domain: domain,
            accountID: accountID,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> in
            return APIService.Persist.persistStatus(
                managedObjectContext: self.backgroundManagedObjectContext,
                domain: domain,
                query: nil,
                response: response,
                persistType: .user,
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
