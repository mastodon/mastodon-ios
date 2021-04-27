//
//  APIService+FollowRequest.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/27.
//

import Foundation

import UIKit
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
    func acceptFollowRequest(
            mastodonUserID: MastodonUser.ID,
            mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
        ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
            let domain = mastodonAuthenticationBox.domain
            let authorization = mastodonAuthenticationBox.userAuthorization
            let requestMastodonUserID = mastodonAuthenticationBox.userID
            
            return Mastodon.API.Account.acceptFollowRequest(
                session: session,
                domain: domain,
                userID: mastodonUserID,
                authorization: authorization)
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> in
                let managedObjectContext = self.backgroundManagedObjectContext
                return managedObjectContext.performChanges {
                    let requestMastodonUserRequest = MastodonUser.sortedFetchRequest
                    requestMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: requestMastodonUserID)
                    requestMastodonUserRequest.fetchLimit = 1
                    guard let requestMastodonUser = managedObjectContext.safeFetch(requestMastodonUserRequest).first else { return }

                    let lookUpMastodonUserRequest = MastodonUser.sortedFetchRequest
                    lookUpMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: mastodonUserID)
                    lookUpMastodonUserRequest.fetchLimit = 1
                    let lookUpMastodonuser = managedObjectContext.safeFetch(lookUpMastodonUserRequest).first
                    
                    if let lookUpMastodonuser = lookUpMastodonuser {
                        let entity = response.value
                        APIService.CoreData.update(user: lookUpMastodonuser, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: response.networkDate)
                    }
                }
                .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Relationship> in
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
    
    func rejectFollowRequest(
            mastodonUserID: MastodonUser.ID,
            mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
        ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
            let domain = mastodonAuthenticationBox.domain
            let authorization = mastodonAuthenticationBox.userAuthorization
            let requestMastodonUserID = mastodonAuthenticationBox.userID
            
            return Mastodon.API.Account.rejectFollowRequest(
                session: session,
                domain: domain,
                userID: mastodonUserID,
                authorization: authorization)
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> in
                let managedObjectContext = self.backgroundManagedObjectContext
                return managedObjectContext.performChanges {
                    let requestMastodonUserRequest = MastodonUser.sortedFetchRequest
                    requestMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: requestMastodonUserID)
                    requestMastodonUserRequest.fetchLimit = 1
                    guard let requestMastodonUser = managedObjectContext.safeFetch(requestMastodonUserRequest).first else { return }

                    let lookUpMastodonUserRequest = MastodonUser.sortedFetchRequest
                    lookUpMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: mastodonUserID)
                    lookUpMastodonUserRequest.fetchLimit = 1
                    let lookUpMastodonuser = managedObjectContext.safeFetch(lookUpMastodonUserRequest).first
                    
                    if let lookUpMastodonuser = lookUpMastodonuser {
                        let entity = response.value
                        APIService.CoreData.update(user: lookUpMastodonuser, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: response.networkDate)
                    }
                }
                .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Relationship> in
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
