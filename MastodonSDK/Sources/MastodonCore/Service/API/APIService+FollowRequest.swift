//
//  APIService+FollowRequest.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/27.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
    
    public func followRequest(
        userID: Mastodon.Entity.Account.ID,
        query: Mastodon.API.Account.FollowReqeustQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let response = try await Mastodon.API.Account.followRequest(
            session: session,
            domain: authenticationBox.domain,
            userID: userID,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let request = MastodonUser.sortedFetchRequest
            request.predicate = MastodonUser.predicate(
                domain: authenticationBox.domain,
                id: authenticationBox.userID
            )
            request.fetchLimit = 1
            guard let user = managedObjectContext.safeFetch(request).first else { return }
            guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else { return }
            
            Persistence.MastodonUser.update(
                mastodonUser: user,
                context: Persistence.MastodonUser.RelationshipContext(
                    entity: response.value,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }

}
