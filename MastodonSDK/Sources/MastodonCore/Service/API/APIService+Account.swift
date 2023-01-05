//
//  APIService+Account.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import os.log
import Foundation
import Combine
import CommonOSLog
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
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let result = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: domain,
                    entity: response.value,
                    cache: nil,
                    networkDate: response.networkDate
                )
            )
            
            let flag = result.isNewInsertion ? "+" : "-"
            let logger = Logger(subsystem: "APIService", category: "AccountInfo")
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch mastodon user [\(flag)](\(response.value.id))\(response.value.username)")
        }
        
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
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
            let logger = Logger(subsystem: "Account", category: "API")
            let account = response.value
            
            let managedObjectContext = self.backgroundManagedObjectContext
            return managedObjectContext.performChanges {
                let result = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: domain,
                        entity: account,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
                let flag = result.isNewInsertion ? "+" : "-"
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): mastodon user [\(flag)](\(result.user.id))\(result.user.username) verifed")
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Account> in
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
    
    public func accountUpdateCredentials(
        domain: String,
        query: Mastodon.API.Account.UpdateCredentialQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        let logger = Logger(subsystem: "Account", category: "API")
        
        let response = try await Mastodon.API.Account.updateCredentials(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let result = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: domain,
                    entity: response.value,
                    cache: nil,
                    networkDate: response.networkDate
                )
            )
            let flag = result.isNewInsertion ? "+" : "-"
            let userID = response.value.id
            let username = response.value.username
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): mastodon user [\(flag)](\(userID)\(username) verifed")
        }

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
        
        let response = try await Mastodon.API.Account.followedTags(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user

            for entity in response.value {
                _ = Persistence.Tag.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Tag.PersistContext(
                        domain: domain,
                        entity: entity,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
            }
        }
        
        return response
    }   // end func
}
