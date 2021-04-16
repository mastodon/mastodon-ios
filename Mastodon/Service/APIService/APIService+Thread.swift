//
//  APIService+Thread.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    func statusContext(
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Context>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        guard domain == mastodonAuthenticationBox.domain else {
            return Fail(error: APIError.implicit(.badRequest)).eraseToAnyPublisher()
        }
        
        return Mastodon.API.Statuses.statusContext(
            session: session,
            domain: domain,
            statusID: statusID,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Context>, Error> in
            return APIService.Persist.persistStatus(
                managedObjectContext: self.backgroundManagedObjectContext,
                domain: domain,
                query: nil,
                response: response.map { $0.ancestors + $0.descendants },
                persistType: .lookUp,
                requestMastodonUserID: nil,
                log: OSLog.api
            )
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Context> in
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
