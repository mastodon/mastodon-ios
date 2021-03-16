//
//  APIService+Account.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine
import CommonOSLog
import MastodonSDK

extension APIService {
    
    func accountVerifyCredentials(
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        return Mastodon.API.Account.verifyCredentials(
            session: session,
            domain: domain,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
            let log = OSLog.api
            let account = response.value
            
            return self.backgroundManagedObjectContext.performChanges {
                let (mastodonUser, isCreated) = APIService.CoreData.createOrMergeMastodonUser(
                    into: self.backgroundManagedObjectContext,
                    for: nil,
                    in: domain,
                    entity: account,
                    networkDate: response.networkDate,
                    log: log)
                let flag = isCreated ? "+" : "-"
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: mastodon user [%s](%s)%s verifed", ((#file as NSString).lastPathComponent), #line, #function, flag, mastodonUser.id, mastodonUser.username)
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func accountUpdateCredentials(
        domain: String,
        query: Mastodon.API.Account.UpdateCredentialQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        return Mastodon.API.Account.updateCredentials(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
            let log = OSLog.api
            let account = response.value
            
            return self.backgroundManagedObjectContext.performChanges {
                let (mastodonUser, isCreated) = APIService.CoreData.createOrMergeMastodonUser(
                    into: self.backgroundManagedObjectContext,
                    for: nil,
                    in: domain,
                    entity: account,
                    networkDate: response.networkDate,
                    log: log)
                let flag = isCreated ? "+" : "-"
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: mastodon user [%s](%s)%s verifed", ((#file as NSString).lastPathComponent), #line, #function, flag, mastodonUser.id, mastodonUser.username)
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func accountRegister(
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
    
}
