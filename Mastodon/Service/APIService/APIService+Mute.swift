//
//  APIService+Mute.swift
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
    
    func toggleMute(
        for mastodonUser: MastodonUser,
        activeMastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        return muteUpdateLocal(
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
        .flatMap { muteQueryType, mastodonUserID -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> in
            return self.muteUpdateRemote(
                muteQueryType: muteQueryType,
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

                self.muteUpdateLocal(
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
    
    // update database local and return mute query update type for remote request
    func muteUpdateLocal(
        mastodonUserObjectID: NSManagedObjectID,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<(Mastodon.API.Account.MuteQueryType, MastodonUser.ID), Error> {
        let domain = mastodonAuthenticationBox.domain
        let requestMastodonUserID = mastodonAuthenticationBox.userID
        
        var _targetMastodonUserID: MastodonUser.ID?
        var _queryType: Mastodon.API.Account.MuteQueryType?
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
            
            let isMuting = (mastodonUser.mutingBy ?? Set()).contains(_requestMastodonUser)
            _queryType = isMuting ? .unmute : .mute
            mastodonUser.update(isMuting: !isMuting, by: _requestMastodonUser)
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
    
    func muteUpdateRemote(
        muteQueryType: Mastodon.API.Account.MuteQueryType,
        mastodonUserID: MastodonUser.ID,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        let domain = mastodonAuthenticationBox.domain
        let authorization = mastodonAuthenticationBox.userAuthorization
        
        return Mastodon.API.Account.mute(
            session: session,
            domain: domain,
            accountID: mastodonUserID,
            muteQueryType: muteQueryType,
            authorization: authorization
        )
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let _ = self else { return }
            switch completion {
            case .failure(let error):
                // TODO: handle error
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] Mute update fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                // TODO: update relationship
                switch muteQueryType {
                case .mute:
                    break
                case .unmute:
                    break
                }
            }
        })
        .eraseToAnyPublisher()
    }
    
}

