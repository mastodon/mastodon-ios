//
//  APIService+Reblog.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-9.
//

import Foundation
import Combine
import MastodonSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    // make local state change only
    func reblog(
        statusObjectID: NSManagedObjectID,
        mastodonUserObjectID: NSManagedObjectID,
        reblogKind: Mastodon.API.Reblog.ReblogKind
    ) -> AnyPublisher<Status.ID, Error> {
        var _targetStatusID: Status.ID?
        let managedObjectContext = backgroundManagedObjectContext
        return managedObjectContext.performChanges {
            let status = managedObjectContext.object(with: statusObjectID) as! Status
            let mastodonUser = managedObjectContext.object(with: mastodonUserObjectID) as! MastodonUser
            let targetStatus = status.reblog ?? status
            let targetStatusID = targetStatus.id
            _targetStatusID = targetStatusID

            let reblogsCount: NSNumber
            switch reblogKind {
            case .reblog:
                targetStatus.update(reblogged: true, by: mastodonUser)
                reblogsCount = NSNumber(value: targetStatus.reblogsCount.intValue + 1)
            case .undoReblog:
                targetStatus.update(reblogged: false, by: mastodonUser)
                reblogsCount = NSNumber(value: max(0, targetStatus.reblogsCount.intValue - 1))
            }
            
            targetStatus.update(reblogsCount: reblogsCount)

        }
        .tryMap { result in
            switch result {
            case .success:
                guard let targetStatusID = _targetStatusID else {
                    throw APIError.implicit(.badRequest)
                }
                return targetStatusID

            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }

    // send reblog request to remote
    func reblog(
        statusID: Mastodon.Entity.Status.ID,
        reblogKind: Mastodon.API.Reblog.ReblogKind,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let domain = mastodonAuthenticationBox.domain
        let authorization = mastodonAuthenticationBox.userAuthorization
        let requestMastodonUserID = mastodonAuthenticationBox.userID
        return Mastodon.API.Reblog.reblog(
            session: session,
            domain: domain,
            statusID: statusID,
            reblogKind: reblogKind,
            authorization: authorization
        )
        .map { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> in
            let log = OSLog.api
            let entity = response.value
            let managedObjectContext = self.backgroundManagedObjectContext

            return managedObjectContext.performChanges {
                guard let requestMastodonUser: MastodonUser = {
                    let request = MastodonUser.sortedFetchRequest
                    request.predicate = MastodonUser.predicate(domain: mastodonAuthenticationBox.domain, id: requestMastodonUserID)
                    request.fetchLimit = 1
                    request.returnsObjectsAsFaults = false
                    return managedObjectContext.safeFetch(request).first
                }() else {
                    return
                }
                
                guard let oldStatus: Status = {
                    let request = Status.sortedFetchRequest
                    request.predicate = Status.predicate(domain: domain, id: statusID)
                    request.fetchLimit = 1
                    request.returnsObjectsAsFaults = false
                    request.relationshipKeyPathsForPrefetching = [#keyPath(Status.reblog)]
                    return managedObjectContext.safeFetch(request).first
                }() else {
                    return
                }

                APIService.CoreData.merge(status: oldStatus, entity: entity.reblog ?? entity, requestMastodonUser: requestMastodonUser, domain: mastodonAuthenticationBox.domain, networkDate: response.networkDate)
                switch reblogKind {
                case .undoReblog:
                    oldStatus.update(reblogsCount: NSNumber(value: max(0, oldStatus.reblogsCount.intValue - 1)))
                default:
                    break
                }
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: did update status %{public}s reblog status to: %{public}s. now %ld reblog", ((#file as NSString).lastPathComponent), #line, #function, entity.id, entity.reblogged.flatMap { $0 ? "reblog" : "unreblog" } ?? "<nil>", entity.reblogsCount )
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
        .switchToLatest()
        .handleEvents(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: error:", ((#file as NSString).lastPathComponent), #line, #function)
                debugPrint(error)
            case .finished:
                break
            }
        })
        .eraseToAnyPublisher()
    }

}
