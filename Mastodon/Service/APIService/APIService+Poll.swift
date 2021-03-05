//
//  APIService+Poll.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import MastodonSDK

extension APIService {
    
    func poll(
        domain: String,
        pollID: Mastodon.Entity.Poll.ID,
        pollObjectID: NSManagedObjectID,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let requestMastodonUserID = mastodonAuthenticationBox.userID
        
        return Mastodon.API.Polls.poll(
            session: session,
            domain: domain,
            pollID: pollID,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error> in
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
                guard let requestMastodonUser = _requestMastodonUser else {
                    assertionFailure()
                    return
                }
                guard let poll = managedObjectContext.object(with: pollObjectID) as? Poll else { return }
                APIService.CoreData.merge(poll: poll, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: response.networkDate)
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Poll> in
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

extension APIService {
    
    /// vote local
    /// # Note
    ///   Not mark the poll voted so that view model could know when to reveal the results
    func vote(
        pollObjectID: NSManagedObjectID,
        mastodonUserObjectID: NSManagedObjectID,
        choices: [Int]
    ) -> AnyPublisher<Mastodon.Entity.Poll.ID, Error> {
        var _targetPollID: Mastodon.Entity.Poll.ID?
        var isPollExpired = false
        var didVotedLocal = false
        
        let managedObjectContext = backgroundManagedObjectContext
        return managedObjectContext.performChanges {
            let poll = managedObjectContext.object(with: pollObjectID) as! Poll
            let mastodonUser = managedObjectContext.object(with: mastodonUserObjectID) as! MastodonUser
            
            _targetPollID = poll.id
            
            if let expiresAt = poll.expiresAt, Date().timeIntervalSince(expiresAt) > 0 {
                isPollExpired = true
                poll.update(expired: true)
                return
            }
            
            let options = poll.options.sorted(by: { $0.index.intValue < $1.index.intValue })
            let votedOptions = poll.options.filter { option in
                (option.votedBy ?? Set()).map { $0.id }.contains(mastodonUser.id)
            }
            guard votedOptions.isEmpty else {
                // if did voted. Do not allow vote again
                didVotedLocal = true
                return
            }
            for option in options {
                let voted = choices.contains(option.index.intValue)
                option.update(voted: voted, by: mastodonUser)
                option.didUpdate(at: option.updatedAt)      // trigger update without change anything
            }
            poll.didUpdate(at: poll.updatedAt)      // trigger update without change anything
        }
        .tryMap { result in
            guard !isPollExpired else {
                throw APIError.explicit(APIError.ErrorReason.voteExpiredPoll)
            }
            guard !didVotedLocal else {
                throw APIError.implicit(APIError.ErrorReason.badRequest)
            }
            switch result {
            case .success:
                guard let targetPollID = _targetPollID else {
                    throw APIError.implicit(.badRequest)
                }
                return targetPollID
                
            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// send vote request to remote
    func vote(
        domain: String,
        pollID: Mastodon.Entity.Poll.ID,
        pollObjectID: NSManagedObjectID,
        choices: [Int],
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let requestMastodonUserID = mastodonAuthenticationBox.userID
        
        let query = Mastodon.API.Polls.VoteQuery(choices: choices)
        return Mastodon.API.Polls.vote(
            session: session,
            domain: domain,
            pollID: pollID,
            query: query,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error> in
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
                guard let requestMastodonUser = _requestMastodonUser else {
                    assertionFailure()
                    return
                }
                guard let poll = managedObjectContext.object(with: pollObjectID) as? Poll else { return }
                APIService.CoreData.merge(poll: poll, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: response.networkDate)
            }
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<Mastodon.Entity.Poll> in
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
