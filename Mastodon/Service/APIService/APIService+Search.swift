//
//  APIService+Search.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import Combine
import MastodonSDK
import CommonOSLog

extension APIService {
 
    func search(
        domain: String,
        query: Mastodon.API.V2.Search.Query,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let requestMastodonUserID = mastodonAuthenticationBox.userID

        return Mastodon.API.V2.Search.search(session: session, domain: domain, query: query, authorization: authorization)
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> in
                // persist status
                let statusResponse = response.map { $0.statuses }
                return APIService.Persist.persistStatus(
                    managedObjectContext: self.backgroundManagedObjectContext,
                    domain: domain,
                    query: nil,
                    response: statusResponse,
                    persistType: .lookUp,
                    requestMastodonUserID: requestMastodonUserID,
                    log: OSLog.api
                )
                .setFailureType(to: Error.self)
                .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.SearchResult> in
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
