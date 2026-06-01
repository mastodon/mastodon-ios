//
//  APIService+DomainBlock.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/29.
//

import Combine
import CoreData
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
        .eraseToAnyPublisher()
    }


    public func blockDomain(
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
    
    public func unblockDomain(
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
