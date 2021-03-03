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
