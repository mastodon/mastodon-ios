//
//  APIService+Follow.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
    
    /// Toggle friendship between target MastodonUser and current MastodonUser
    ///
    /// Following / Following pending <-> Unfollow
    ///
    /// - Parameters:
    ///   - mastodonUser: target MastodonUser
    ///   - activeMastodonAuthenticationBox: `AuthenticationService.MastodonAuthenticationBox`
    /// - Returns: publisher for `Relationship`
    func toggleFollow(
        for mastodonUser: MastodonUser,
        activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        
        return followUpdateLocal(
            mastodonUserObjectID: mastodonUser.objectID,
            mastodonAuthenticationBox: activeMastodonAuthenticationBox
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            impactFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            impactFeedbackGenerator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] local relationship update fail", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                assertionFailure(error.localizedDescription)
            case .finished:
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] local relationship update success", ((#file as NSString).lastPathComponent), #line, #function)
            break
            }
        }
        .flatMap { followQueryType, mastodonUserID -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> in
            return self.followUpdateRemote(
                followQueryType: followQueryType,
                mastodonUserID: mastodonUserID,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox
            )
        }
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Relationship] remote friendship update fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                // TODO: handle error

                // rollback

                self.followUpdateLocal(
                    mastodonUserObjectID: mastodonUser.objectID,
                    mastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
                .sink { completion in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Friendship] rollback finish", ((#file as NSString).lastPathComponent), #line, #function)
                } receiveValue: { _ in
                    // do nothing
                    notificationFeedbackGenerator.prepare()
                    notificationFeedbackGenerator.notificationOccurred(.error)
                }
                .store(in: &self.disposeBag)

            case .finished:
                notificationFeedbackGenerator.notificationOccurred(.success)
                os_log("%{public}s[%{public}ld], %{public}s: [Friendship] remote friendship update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        })
        .eraseToAnyPublisher()
    }
    
}

extension APIService {
    
    // update database local and return follow query update type for remote request
    func followUpdateLocal(
        mastodonUserObjectID: NSManagedObjectID,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<(Mastodon.API.Account.FollowQueryType, MastodonUser.ID), Error> {
        let domain = mastodonAuthenticationBox.domain
        let requestMastodonUserID = mastodonAuthenticationBox.userID
        
        var _targetMastodonUserID: MastodonUser.ID?
        var _queryType: Mastodon.API.Account.FollowQueryType?
        let managedObjectContext = backgroundManagedObjectContext
        
        return managedObjectContext.performChanges {
            let request = MastodonUser.sortedFetchRequest
            request.predicate = MastodonUser.predicate(domain: domain, id: requestMastodonUserID)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            guard let _requestMastodonUser = managedObjectContext.safeFetch(request).first else {
                assertionFailure()
                return
            }
            
            let mastodonUser = managedObjectContext.object(with: mastodonUserObjectID) as! MastodonUser
            _targetMastodonUserID = mastodonUser.id
            
            let isPending = (mastodonUser.followRequestedBy ?? Set()).contains(_requestMastodonUser)
            let isFollowing = (mastodonUser.followingBy ?? Set()).contains(_requestMastodonUser)
            
            if isFollowing || isPending {
                _queryType = .unfollow
                mastodonUser.update(isFollowing: false, by: _requestMastodonUser)
                mastodonUser.update(isFollowRequested: false, by: _requestMastodonUser)
            } else {
                _queryType = .follow(query: Mastodon.API.Account.FollowQuery())
                if mastodonUser.locked {
                    mastodonUser.update(isFollowing: false, by: _requestMastodonUser)
                    mastodonUser.update(isFollowRequested: true, by: _requestMastodonUser)
                } else {
                    mastodonUser.update(isFollowing: true, by: _requestMastodonUser)
                    mastodonUser.update(isFollowRequested: false, by: _requestMastodonUser)
                }
            }
        }
        .tryMap { result in
            switch result {
            case .success:
                guard let targetMastodonUserID = _targetMastodonUserID,
                      let queryType = _queryType else {
                    throw APIError.implicit(.badRequest)
                }
                return (queryType, targetMastodonUserID)
                
            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    func followUpdateRemote(
        followQueryType: Mastodon.API.Account.FollowQueryType,
        mastodonUserID: MastodonUser.ID,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        let domain = mastodonAuthenticationBox.domain
        let authorization = mastodonAuthenticationBox.userAuthorization
        let requestMastodonUserID = mastodonAuthenticationBox.userID
        
        return Mastodon.API.Account.follow(
            session: session,
            domain: domain,
            accountID: mastodonUserID,
            followQueryType: followQueryType,
            authorization: authorization
        )
//        .handleEvents(receiveCompletion: { [weak self] completion in
//            guard let _ = self else { return }
//            switch completion {
//            case .failure(let error):
//                // TODO: handle error
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update follow fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                break
//            case .finished:
//                switch followQueryType {
//                case .follow:
//                    break
//                case .unfollow:
//                    break
//                }
//            }
//        })
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> in
            let managedObjectContext = self.backgroundManagedObjectContext
            return managedObjectContext.performChanges {
                let requestMastodonUserRequest = MastodonUser.sortedFetchRequest
                requestMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: requestMastodonUserID)
                requestMastodonUserRequest.fetchLimit = 1
                guard let requestMastodonUser = managedObjectContext.safeFetch(requestMastodonUserRequest).first else { return }

                let lookUpMastodonUserRequest = MastodonUser.sortedFetchRequest
                lookUpMastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: mastodonUserID)
                lookUpMastodonUserRequest.fetchLimit = 1
                let lookUpMastodonuser = managedObjectContext.safeFetch(lookUpMastodonUserRequest).first
                
                if let lookUpMastodonuser = lookUpMastodonuser {
                    let entity = response.value
                    APIService.CoreData.update(user: lookUpMastodonuser, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: response.networkDate)
                }
            }
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Relationship> in
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
