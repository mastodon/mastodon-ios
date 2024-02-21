//
//  APIService+DomainBlock.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/29.
//

import Combine
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

    public func toggleDomainBlock(
        account: Mastodon.Entity.Account,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Empty> {
        guard let originalRelationship = try await relationship(forAccounts: [account], authenticationBox: authenticationBox).value.first else {
            throw APIError.implicit(.badRequest)
        }

        let response: Mastodon.Response.Content<Mastodon.Entity.Empty>
        let domainBlocking = originalRelationship.domainBlocking

        if domainBlocking {
            response = try await unblockDomain(account: account, authorizationBox: authenticationBox)
        } else {
            response = try await blockDomain(account: account, authorizationBox: authenticationBox)
        }

        return response
    }

    func blockDomain(
        account: Mastodon.Entity.Account,
        authorizationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Empty> {
        let authorization = authorizationBox.userAuthorization

        guard let domain = account.domainFromAcct else {
            throw APIError.implicit(.badRequest)
        }

        let result = try await Mastodon.API.DomainBlock.blockDomain(
            domain: authorizationBox.domain,
            blockDomain: domain,
            session: session,
            authorization: authorization
        ).singleOutput()

        return result
    }
    
    func unblockDomain(
        account: Mastodon.Entity.Account,
        authorizationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Empty> {
        let authorization = authorizationBox.userAuthorization

        guard let domain = account.domainFromAcct else {
            throw APIError.implicit(.badRequest)
        }

        let result = try await Mastodon.API.DomainBlock.unblockDomain(
            domain: authorizationBox.domain,
            blockDomain: domain,
            session: session,
            authorization: authorization
        ).singleOutput()

        return result
    }
}
