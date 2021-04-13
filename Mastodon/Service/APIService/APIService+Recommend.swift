//
//  APIService+Recommend.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation
import MastodonSDK
import CoreData
import CoreDataStack
import OSLog

extension APIService {
    func recommendAccount(
        domain: String,
        query: Mastodon.API.Suggestions.Query?,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Suggestions.get(session: session, domain: domain, query: query, authorization: authorization)
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> in
                let log = OSLog.api
                return self.backgroundManagedObjectContext.performChanges {
                    response.value.forEach { user in
                        let (mastodonUser,isCreated) = APIService.CoreData.createOrMergeMastodonUser(into: self.backgroundManagedObjectContext, for: nil, in: domain, entity: user, userCache: nil, networkDate: Date(), log: log)
                        let flag = isCreated ? "+" : "-"
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: fetch mastodon user [%s](%s)%s", (#file as NSString).lastPathComponent, #line, #function, flag, mastodonUser.id, mastodonUser.username)
                    }
                }
                .setFailureType(to: Error.self)
                .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Account]> in
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

    func recommendTrends(
        domain: String,
        query: Mastodon.API.Trends.Query?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> {
        Mastodon.API.Trends.get(session: session, domain: domain, query: query)
    }
}
