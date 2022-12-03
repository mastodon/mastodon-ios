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
    
    private struct MastodonMuteContext {
        let sourceUserID: MastodonUser.ID
        let targetUserID: MastodonUser.ID
        let targetUsername: String
        let isMuting: Bool
    }
    
    @discardableResult
    public func getMutes(
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        try await _getMutes(sinceID: nil, limit: nil, authenticationBox: authenticationBox)
    }
    
    private func _getMutes(
        sinceID: Mastodon.Entity.Status.ID?,
        limit: Int?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let managedObjectContext = backgroundManagedObjectContext
        let response = try await Mastodon.API.Account.mutes(
            session: session,
            domain: authenticationBox.domain,
            sinceID: sinceID,
            limit: limit,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let userIDs = response.value.map { $0.id }
        let predicate = MastodonUser.predicate(domain: authenticationBox.domain, ids: userIDs)

        let fetchRequest = MastodonUser.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.includesPropertyValues = false
        
        try await managedObjectContext.performChanges {
            let users = try managedObjectContext.fetch(fetchRequest) as! [MastodonUser]
            
            for user in users {
                user.deleteStatusAndNotificationFeeds(in: managedObjectContext)
            }
        }

        return response
    }
    
    public func toggleMute(
        user: ManagedObjectRecord<MastodonUser>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let logger = Logger(subsystem: "APIService", category: "Mute")
        
        let managedObjectContext = backgroundManagedObjectContext
        let muteContext: MastodonMuteContext = try await managedObjectContext.performChanges {
            guard let user = user.object(in: managedObjectContext),
                  let authentication = authenticationBox.authenticationRecord.object(in: managedObjectContext)
            else {
                throw APIError.implicit(.badRequest)
            }
            
            let me = authentication.user
            let isMuting = user.mutingBy.contains(me)
            
            // toggle mute state
            user.update(isMuting: !isMuting, by: me)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user[\(user.id)](\(user.username)) mute state: \(!isMuting)")
            return MastodonMuteContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                targetUsername: user.username,
                isMuting: isMuting
            )
        }
        
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
        do {
            if muteContext.isMuting {
                let response = try await Mastodon.API.Account.unmute(
                    session: session,
                    domain: authenticationBox.domain,
                    accountID: muteContext.targetUserID,
                    authorization: authenticationBox.userAuthorization
                ).singleOutput()
                try await getMutes(authenticationBox: authenticationBox)
                result = .success(response)
            } else {
                let response = try await Mastodon.API.Account.mute(
                    session: session,
                    domain: authenticationBox.domain,
                    accountID: muteContext.targetUserID,
                    authorization: authenticationBox.userAuthorization
                ).singleOutput()
                try await getMutes(authenticationBox: authenticationBox)
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute failure: \(error.localizedDescription)")
        }
        
        try await managedObjectContext.performChanges {
            guard let user = user.object(in: managedObjectContext),
                  let authentication = authenticationBox.authenticationRecord.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            
            switch result {
            case .success(let response):
                let relationship = response.value
                Persistence.MastodonUser.update(
                    mastodonUser: user,
                    context: Persistence.MastodonUser.RelationshipContext(
                        entity: relationship,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute state: \(relationship.muting.debugDescription)")
            case .failure:
                // rollback
                user.update(isMuting: muteContext.isMuting, by: me)
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute state")
            }
        }
        
        let response = try result.get()
        return response
    }
    
}

