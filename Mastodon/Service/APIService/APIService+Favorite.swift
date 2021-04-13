//
//  APIService+Favorite.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/8.
//


import Foundation
import Combine
import MastodonSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    // make local state change only
    func favorite(
        statusObjectID: NSManagedObjectID,
        mastodonUserObjectID: NSManagedObjectID,
        favoriteKind: Mastodon.API.Favorites.FavoriteKind
    ) -> AnyPublisher<Status.ID, Error> {
        var _targetStatusID: Status.ID?
        let managedObjectContext = backgroundManagedObjectContext
        return managedObjectContext.performChanges {
            let status = managedObjectContext.object(with: statusObjectID) as! Status
            let mastodonUser = managedObjectContext.object(with: mastodonUserObjectID) as! MastodonUser
            let targetStatus = status.reblog ?? status
            let targetStatusID = targetStatus.id
            _targetStatusID = targetStatusID
            
            targetStatus.update(liked: favoriteKind == .create, by: mastodonUser)

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
    
    // send favorite request to remote
    func favorite(
        statusID: Mastodon.Entity.Status.ID,
        favoriteKind: Mastodon.API.Favorites.FavoriteKind,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let requestMastodonUserID = mastodonAuthenticationBox.userID
        return Mastodon.API.Favorites.favorites(domain: mastodonAuthenticationBox.domain, statusID: statusID, session: session, authorization: authorization, favoriteKind: favoriteKind)
            .map { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> in
                let log = OSLog.api
                let entity = response.value
                let managedObjectContext = self.backgroundManagedObjectContext
                    
                return managedObjectContext.performChanges {
                    let _requestMastodonUser: MastodonUser? = {
                        let request = MastodonUser.sortedFetchRequest
                        request.predicate = MastodonUser.predicate(domain: mastodonAuthenticationBox.domain, id: requestMastodonUserID)
                        request.fetchLimit = 1
                        request.returnsObjectsAsFaults = false
                        do {
                            return try managedObjectContext.fetch(request).first
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return nil
                        }
                    }()
                    let _oldStatus: Status? = {
                        let request = Status.sortedFetchRequest
                        request.predicate = Status.predicate(domain: mastodonAuthenticationBox.domain, id: statusID)
                        request.fetchLimit = 1
                        request.returnsObjectsAsFaults = false
                        request.relationshipKeyPathsForPrefetching = [#keyPath(Status.reblog)]
                        do {
                            return try managedObjectContext.fetch(request).first
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return nil
                        }
                    }()
                    
                    guard let requestMastodonUser = _requestMastodonUser,
                          let oldStatus = _oldStatus else {
                        assertionFailure()
                        return
                    }
                    APIService.CoreData.merge(status: oldStatus, entity: entity, requestMastodonUser: requestMastodonUser, domain: mastodonAuthenticationBox.domain, networkDate: response.networkDate)
                    if favoriteKind == .destroy {
                        oldStatus.update(favouritesCount: NSNumber(value: max(0, oldStatus.favouritesCount.intValue - 1)))
                    }
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: did update status %{public}s like status to: %{public}s. now %ld likes", ((#file as NSString).lastPathComponent), #line, #function, entity.id, entity.favourited.flatMap { $0 ? "like" : "unlike" } ?? "<nil>", entity.favouritesCount )
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

extension APIService {
    func favoritedStatuses(
        limit: Int = onceRequestStatusMaxCount,
        maxID: String? = nil,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> {

        let requestMastodonUserID = mastodonAuthenticationBox.userID
        let query = Mastodon.API.Favorites.FavoriteStatusesQuery(limit: limit, minID: nil, maxID: maxID)
        return Mastodon.API.Favorites.favoritedStatus(
            domain: mastodonAuthenticationBox.domain,
            session: session,
            authorization: mastodonAuthenticationBox.userAuthorization,
            query: query
        )
            .map { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> in
                let log = OSLog.api
                
                return APIService.Persist.persistStatus(
                    managedObjectContext: self.backgroundManagedObjectContext,
                    domain: mastodonAuthenticationBox.domain,
                    query: query,
                    response: response,
                    persistType: .likeList,
                    requestMastodonUserID: requestMastodonUserID,
                    log: log
                )
                .setFailureType(to: Error.self)
                .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Status]> in
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
            .eraseToAnyPublisher()
    }
}
