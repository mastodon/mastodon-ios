//
//  APIService+Follower.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
    
    func followers(
        userID: Mastodon.Entity.Account.ID,
        maxID: String?,
        authorizationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let domain = authorizationBox.domain
        let authorization = authorizationBox.userAuthorization
        let requestMastodonUserID = authorizationBox.userID
        
        let query = Mastodon.API.Account.FollowerQuery(
            maxID: maxID,
            limit: nil
        )
        return Mastodon.API.Account.followers(
            session: session,
            domain: domain,
            userID: userID,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> in
            let managedObjectContext = self.backgroundManagedObjectContext
            return managedObjectContext.performChanges {
                let requestMastodonUserRequest = MastodonUser.sortedFetchRequest
                requestMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: requestMastodonUserID)
                requestMastodonUserRequest.fetchLimit = 1
                guard let requestMastodonUser = managedObjectContext.safeFetch(requestMastodonUserRequest).first else { return }

                for entity in response.value {
                    _ = APIService.CoreData.createOrMergeMastodonUser(
                        into: managedObjectContext,
                        for: requestMastodonUser,
                        in: domain,
                        entity: entity,
                        userCache: nil,
                        networkDate: response.networkDate,
                        log: .api
                    )
                }
            }
            .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Account]> in
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
