//
//  APIService+Relationship.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
 
    func relationship(
        domain: String,
        accountIDs: [Mastodon.Entity.Account.ID],
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Relationship]>, Error> {
        fatalError()
//        let authorization = authorizationBox.userAuthorization
//        let requestMastodonUserID = authorizationBox.userID
//        let query = Mastodon.API.Account.AccountStatuseseQuery(
//            maxID: maxID,
//            sinceID: sinceID,
//            excludeReplies: excludeReplies,
//            excludeReblogs: excludeReblogs,
//            onlyMedia: onlyMedia,
//            limit: limit
//        )
//
//        return Mastodon.API.Account.statuses(
//            session: session,
//            domain: domain,
//            accountID: accountID,
//            query: query,
//            authorization: authorization
//        )
//        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> in
//            return APIService.Persist.persistStatus(
//                managedObjectContext: self.backgroundManagedObjectContext,
//                domain: domain,
//                query: nil,
//                response: response,
//                persistType: .user,
//                requestMastodonUserID: requestMastodonUserID,
//                log: OSLog.api
//            )
//            .setFailureType(to: Error.self)
//            .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Status]> in
//                switch result {
//                case .success:
//                    return response
//                case .failure(let error):
//                    throw error
//                }
//            }
//            .eraseToAnyPublisher()
//        }
//        .eraseToAnyPublisher()
    }
    
}
