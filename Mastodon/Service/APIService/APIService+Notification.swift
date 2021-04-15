//
//  APIService+Notification.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import OSLog

extension APIService {
    func allNotifications(
        domain: String,
        query: Mastodon.API.Notifications.Query,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Notification]>, Error>
    {
        let authorization = mastodonAuthenticationBox.userAuthorization
        return Mastodon.API.Notifications.getNotifications(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization)
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Notification]>, Error> in
                let log = OSLog.api
                return self.backgroundManagedObjectContext.performChanges {
                    response.value.forEach { notification in
                        let (mastodonUser, _) = APIService.CoreData.createOrMergeMastodonUser(into: self.backgroundManagedObjectContext, for: nil, in: domain, entity: notification.account, userCache: nil, networkDate: Date(), log: log)
                        var status: Status?
                        if let statusEntity = notification.status {
                            let (statusInCoreData, _, _) = APIService.CoreData.createOrMergeStatus(
                                into: self.backgroundManagedObjectContext,
                                for: nil,
                                domain: domain,
                                entity: statusEntity,
                                statusCache: nil,
                                userCache: nil,
                                networkDate: Date(),
                                log: log)
                            status = statusInCoreData
                        }
                        // use constrain to avoid repeated save
                        let notification = MastodonNotification.insert(into: self.backgroundManagedObjectContext, domain: domain, property: MastodonNotification.Property(id: notification.id, type: notification.type.rawValue, account: mastodonUser, status: status, createdAt: notification.createdAt))
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: fetch mastodon user [%s](%s)", (#file as NSString).lastPathComponent, #line, #function, notification.type, notification.account.username)
                    }
                }
                .setFailureType(to: Error.self)
                .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Notification]> in
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
