//
//  APIService+Status.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import MastodonSDK

extension APIService {
 
    func publishStatus(
        domain: String,
        query: Mastodon.API.Statuses.PublishStatusQuery,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Statuses.publishStatus(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> in
            return APIService.Persist.persistStatus(
                managedObjectContext: self.backgroundManagedObjectContext,
                domain: domain,
                query: nil,
                response: response.map { [$0] },
                persistType: .lookUp,
                requestMastodonUserID: nil,
                log: OSLog.api
            )
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Status> in
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

    func status(
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let authorization = authorizationBox.userAuthorization
        return Mastodon.API.Statuses.status(
            session: session,
            domain: domain,
            statusID: statusID,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> in
            return APIService.Persist.persistStatus(
                managedObjectContext: self.backgroundManagedObjectContext,
                domain: domain,
                query: nil,
                response: response.map { [$0] },
                persistType: .lookUp,
                requestMastodonUserID: nil,
                log: OSLog.api
            )
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Status> in
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
