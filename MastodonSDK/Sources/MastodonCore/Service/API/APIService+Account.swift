//
//  APIService+Account.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import CoreDataStack
import Foundation
import Combine
import MastodonCommon
import MastodonSDK

extension APIService {
    public func authenticatedUserInfo(
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        try await accountInfo(
            domain: authenticationBox.domain,
            userID: authenticationBox.userID,
            authorization: authenticationBox.userAuthorization
        )
    }

    public func accountInfo(
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        let response = try await Mastodon.API.Account.accountInfo(
            session: session,
            domain: domain,
            userID: userID,
            authorization: authorization
        ).singleOutput()
        
        return response
    }
    
}

extension APIService {
    
    public func accountVerifyCredentials(
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        return Mastodon.API.Account.verifyCredentials(
            session: session,
            domain: domain,
            authorization: authorization
        )
    }
    
    public func accountUpdateCredentials(
        domain: String,
        query: Mastodon.API.Account.UpdateCredentialQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        let response = try await Mastodon.API.Account.updateCredentials(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        return response
    }
    
    public func accountRegister(
        domain: String,
        query: Mastodon.API.Account.RegisterQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> {
        return Mastodon.API.Account.register(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
    
    public func accountLookup(
        domain: String,
        query: Mastodon.API.Account.AccountLookupQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        return Mastodon.API.Account.lookupAccount(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
    
}

extension APIService {
    @discardableResult
    public func getFollowedTags(
        domain: String,
        query: Mastodon.API.Account.FollowedTagsQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Tag]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let followedTags = try await Mastodon.API.Account.followedTags(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()

        return followedTags
    }
}

extension APIService {
    public func fetchUser(username: String, domain: String, authenticationBox: MastodonAuthenticationBox)
    async throws -> Mastodon.Entity.Account? {
        let query = Mastodon.API.Account.AccountLookupQuery(acct: "\(username)@\(domain)")
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Account.lookupAccount(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authorization
        ).singleOutput()

        return response.value
    }
}
