//
//  APIService+Relationship.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
 
    func relationship(
        domain: String,
        accountIDs: [Mastodon.Entity.Account.ID],
        authorizationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Relationship]>, Error> {
        let authorization = authorizationBox.userAuthorization
        let requestMastodonUserID = authorizationBox.userID
        let query = Mastodon.API.Account.RelationshipQuery(
            ids: accountIDs
        )

        return Mastodon.API.Account.relationships(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Relationship]>, Error> in
            let managedObjectContext = self.backgroundManagedObjectContext
            return managedObjectContext.performChanges {
                let requestMastodonUserRequest = MastodonUser.sortedFetchRequest
                requestMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: requestMastodonUserID)
                requestMastodonUserRequest.fetchLimit = 1
                guard let requestMastodonUser = managedObjectContext.safeFetch(requestMastodonUserRequest).first else { return }

                let lookUpMastodonUserRequest = MastodonUser.sortedFetchRequest
                lookUpMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, ids: accountIDs)
                lookUpMastodonUserRequest.fetchLimit = accountIDs.count
                let lookUpMastodonusers = managedObjectContext.safeFetch(lookUpMastodonUserRequest)
                
                for user in lookUpMastodonusers {
                    guard let entity = response.value.first(where: { $0.id == user.id }) else { continue }
                    APIService.CoreData.update(user: user, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: response.networkDate)
                }
            }
            .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> in
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
