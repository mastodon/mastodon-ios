//
//  APIService+DomainBlock.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/29.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import MastodonSDK

extension APIService {
    
    func getDomainblocks(
        domain: String,
        limit: Int = onceRequestDomainBlocksMaxCount,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
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
            return self.backgroundManagedObjectContext.performChanges {
                response.value.forEach { domain in
                    // use constrain to avoid repeated save
                    let _ = DomainBlock.insert(
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
        domain: String,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<String>, Error> {
        let authorization = authorizationBox.userAuthorization

        return Mastodon.API.DomainBlock.blockDomain(
            domain: authorizationBox.domain,
            blockDomain: domain,
            session: session,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<String>, Error> in
            return self.backgroundManagedObjectContext.performChanges {
                let _ = DomainBlock.insert(
                    into: self.backgroundManagedObjectContext,
                    blockedDomain: domain,
                    domain: authorizationBox.domain,
                    userID: authorizationBox.userID
                )
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<String> in
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
        domain: String,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<String>, Error> {
        let authorization = authorizationBox.userAuthorization
        
        return Mastodon.API.DomainBlock.unblockDomain(
            domain: authorizationBox.domain,
            blockDomain: domain,
            session: session,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<String>, Error> in
            return self.backgroundManagedObjectContext.performChanges {
//                let _ = DomainBlock.insert(
//                    into: self.backgroundManagedObjectContext,
//                    blockedDomain: domain,
//                    domain: authorizationBox.domain,
//                    userID: authorizationBox.userID
//                )
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<String> in
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
