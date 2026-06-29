//
//  APIService+Account.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine
import MastodonCommon
import MastodonSDK

extension APIService {
    public func accountInfo(_ authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Entity.Account {
        let account = try await Mastodon.API.Account.verifyCredentials(session: session, domain: authenticationBox.domain, authorization: authenticationBox.userAuthorization)
        
        PersistenceManager.shared.cacheAccount(account, forUserID: authenticationBox.authentication.userIdentifier())
        
        return account
    }
    
    public func accountInfo(domain: String, userID: String, authorization: Mastodon.API.OAuth.Authorization) async throws -> Mastodon.Entity.Account {
        let account = try await Mastodon.API.Account.accountInfo(
            session: session,
            domain: domain,
            userID: userID,
            authorization: authorization
        ).singleOutput().value
        return account
    }
    
    public func accountsInfo(userIDs: [String], authenticationBox: MastodonAuthenticationBox) async throws -> [Mastodon.Entity.Account] {
        let accounts = try await Mastodon.API.Account.accountsInfo(
            session: session,
            domain: authenticationBox.domain,
            userIDs: userIDs,
            authorization: authenticationBox.userAuthorization
        ).singleOutput().value
        return accounts
    }
}

extension APIService {
    
    private func saveAndActivateVerifiedUser(account: Mastodon.Entity.Account,
                           domain: String,
                           clientID: String,
                           clientSecret: String,
                           authorization: Mastodon.API.OAuth.Authorization) -> MastodonAuthenticationBox {
        let authentication = MastodonAuthentication.createFrom(domain: domain,
                                                               userID: account.id,
                                                               username: account.username,
                                                               appAccessToken: authorization.accessToken,  // TODO: swap app token
                                                               userAccessToken: authorization.accessToken,
                                                               clientID: clientID,
                                                               clientSecret: clientSecret,
                                                               accountCreatedAt: account.createdAt)
        
        let authBox = MastodonAuthenticationBox(authentication: authentication)
        PersistenceManager.shared.cacheAccount(account, forUserID: authentication.userIdentifier())
        AuthenticationServiceProvider.shared.activateAuthentication(authBox)
        return authBox
    }
    
    public func verifyAndActivateUser(
        domain: String,
        clientID: String,
        clientSecret: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<(Mastodon.Entity.Account, MastodonAuthenticationBox), Error> {
        return Mastodon.API.Account.verifyCredentials(
            session: session,
            domain: domain,
            authorization: authorization
        ).tryMap { response -> (Mastodon.Entity.Account, MastodonAuthenticationBox) in
            let account = response.value
            let authBox = self.saveAndActivateVerifiedUser(account: account, domain: domain, clientID: clientID, clientSecret: clientSecret, authorization: authorization)
            return (account, authBox)
        }
        .eraseToAnyPublisher()
    }
    
    public func verifyAndActivateUser(
        domain: String,
        clientID: String,
        clientSecret: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> (Mastodon.Entity.Account, MastodonAuthenticationBox) {
        let account = try await Mastodon.API.Account.verifyCredentials(
            session: session,
            domain: domain,
            authorization: authorization
        )
        let authBox = self.saveAndActivateVerifiedUser(account: account, domain: domain, clientID: clientID, clientSecret: clientSecret, authorization: authorization)
        return (account, authBox)
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
        
        PersistenceManager.shared.cacheAccount(response.value, forUserID: MastodonUserIdentifier(domain: domain, userID: response.value.id))
        NotificationCenter.default.post(name: .userFetched, object: nil)
        
        return response
    }
    
    public func accountRegister(
        domain: String,
        query: Mastodon.API.Account.RegisterQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Entity.Token {
        return try await Mastodon.API.Account.register(
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
    public func fetchNotMeUser(username: String, domain: String, authenticationBox: MastodonAuthenticationBox)
    async throws -> Mastodon.Entity.Account? {
        let query = Mastodon.API.Account.AccountLookupQuery(acct: "\(username)@\(domain)")
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Account.lookupAccount(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authorization
        ).singleOutput()

        let fetchedAccount = response.value
        
        
        return fetchedAccount
    }
}

extension APIService {
    public func featureAccount(_ accountID: Mastodon.Entity.Account.ID, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.featureAccount(
            session: session,
            domain: authenticationBox.domain,
            accountToFeature: accountID,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let updatedRelationship = response.value
        return updatedRelationship
    }
    
    public func stopFeaturingAccount(_ accountID: Mastodon.Entity.Account.ID, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.stopFeaturingAccount(
            session: session,
            domain: authenticationBox.domain,
            accountToStopFeaturing: accountID,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let updatedRelationship = response.value
        return updatedRelationship
    }
    
    public func removeFollower(_ accountID: Mastodon.Entity.Account.ID, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.removeFromFollowers(
            session: session,
            domain: authenticationBox.domain,
            accountToRemove: accountID,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let updatedRelationship = response.value
        return updatedRelationship
    }
    
    public func setPersonalNote(_ accountID: Mastodon.Entity.Account.ID, note: String, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.setPersonalNote(
            session: session,
            domain: authenticationBox.domain,
            account: accountID,
            note: note,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let updatedRelationship = response.value
        return updatedRelationship
    }
}

extension APIService {
    public func updateTabDisplaySettings(showFeaturedTab: Bool, showMediaTab: Bool, showMediaReplies: Bool, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Profile {
        let response = try await Mastodon.API.Account.updateTabDisplaySettings(
            session: session,
            domain: authenticationBox.domain,
            query: Mastodon.API.Account.UpdateTabDisplaySettingsQuery(showFeaturedTab:  showFeaturedTab, showMediaTab: showMediaTab, showMediaReplies:  showMediaReplies),
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let updated = response.value
        return updated
    }
}
