//
//  APIService+Status+Publish.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-20.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {

    func publishStatus(
        domain: String,
        query: Mastodon.API.Statuses.PublishStatusQuery,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Statuses.publishStatus(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> in
            #if APP_EXTENSION
            return Just(response)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            #else
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
            #endif
        }
        .eraseToAnyPublisher()
    }

}
