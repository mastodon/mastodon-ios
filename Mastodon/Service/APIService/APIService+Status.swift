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

    func status(
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorizationBox: MastodonAuthenticationBox
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
    
    func deleteStatus(
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorizationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let authorization = authorizationBox.userAuthorization
        let query = Mastodon.API.Statuses.DeleteStatusQuery(id: statusID)
        return Mastodon.API.Statuses.deleteStatus(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> in
            return self.backgroundManagedObjectContext.performChanges{
                // fetch old Status
                let oldStatus: Status? = {
                    let request = Status.sortedFetchRequest
                    request.predicate = Status.predicate(domain: domain, id: response.value.id)
                    request.fetchLimit = 1
                    request.returnsObjectsAsFaults = false
                    do {
                        return try self.backgroundManagedObjectContext.fetch(request).first
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return nil
                    }
                }()
                if let status = oldStatus {
                    let homeTimelineIndexes = status.homeTimelineIndexes ?? Set()
                    for homeTimelineIndex in homeTimelineIndexes {
                        self.backgroundManagedObjectContext.delete(homeTimelineIndex)
                    }
                    let inNotifications = status.inNotifications ?? Set()
                    for notification in inNotifications {
                        self.backgroundManagedObjectContext.delete(notification)
                    }
                    self.backgroundManagedObjectContext.delete(status)
                }
            }
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
