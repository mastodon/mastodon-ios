//
//  APIService+DomainBlock.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/29.
//

import Combine
import CommonOSLog
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension APIService {
    func getDomainblocks(
        domain: String,
        limit: Int = onceRequestDomainBlocksMaxCount,
        authorizationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[String]>, Error> {
        let authorization = authorizationBox.userAuthorization
        
        let query = Mastodon.API.DomainBlock.Query(
            maxID: nil, sinceID: nil, limit: limit
        )
        return Mastodon.API.DomainBlock.getDomainblocks(
            domain: domain,
            session: session,
            authorization: authorization,
            query: query
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[String]>, Error> in
            self.backgroundManagedObjectContext.performChanges {
                let blockedDomains: [DomainBlock] = {
                    let request = DomainBlock.sortedFetchRequest
                    request.predicate = DomainBlock.predicate(domain: authorizationBox.domain, userID: authorizationBox.userID)
                    request.returnsObjectsAsFaults = false
                    do {
                        return try self.backgroundManagedObjectContext.fetch(request)
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return []
                    }
                }()
                blockedDomains.forEach { self.backgroundManagedObjectContext.delete($0) }
                
                response.value.forEach { domain in
                    // use constrain to avoid repeated save
                    _ = DomainBlock.insert(
                        into: self.backgroundManagedObjectContext,
                        blockedDomain: domain,
                        domain: authorizationBox.domain,
                        userID: authorizationBox.userID
                    )
                }
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<[String]> in
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
 
    func blockDomain(
        user: MastodonUser,
        authorizationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error> {
        let authorization = authorizationBox.userAuthorization

        return Mastodon.API.DomainBlock.blockDomain(
            domain: authorizationBox.domain,
            blockDomain: user.domainFromAcct,
            session: session,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error> in
            self.backgroundManagedObjectContext.performChanges {
                let requestMastodonUserRequest = MastodonUser.sortedFetchRequest
                requestMastodonUserRequest.predicate = MastodonUser.predicate(domain: authorizationBox.domain, id: authorizationBox.userID)
                requestMastodonUserRequest.fetchLimit = 1
                guard let requestMastodonUser = self.backgroundManagedObjectContext.safeFetch(requestMastodonUserRequest).first else { return }
                user.update(isDomainBlocking: true, by: requestMastodonUser)
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Empty> in
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
    
    func unblockDomain(
        user: MastodonUser,
        authorizationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error> {
        let authorization = authorizationBox.userAuthorization
        
        return Mastodon.API.DomainBlock.unblockDomain(
            domain: authorizationBox.domain,
            blockDomain: user.domainFromAcct,
            session: session,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error> in
            self.backgroundManagedObjectContext.performChanges {
                let requestMastodonUserRequest = MastodonUser.sortedFetchRequest
                requestMastodonUserRequest.predicate = MastodonUser.predicate(domain: authorizationBox.domain, id: authorizationBox.userID)
                requestMastodonUserRequest.fetchLimit = 1
                guard let requestMastodonUser = self.backgroundManagedObjectContext.safeFetch(requestMastodonUserRequest).first else { return }
                user.update(isDomainBlocking: false, by: requestMastodonUser)
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Empty> in
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
