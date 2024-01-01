//
//  APIService+Block.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    private struct MastodonBlockContext {
        let sourceUserID: String
        let targetUserID: String
        let targetUsername: String
        let isBlocking: Bool
        let isFollowing: Bool
    }
    
    @discardableResult
    public func getBlocked(
        sinceID: Mastodon.Entity.Status.ID? = nil,
        limit: Int? = nil,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let managedObjectContext = backgroundManagedObjectContext
        let response = try await Mastodon.API.Account.blocks(
            session: session,
            domain: authenticationBox.domain,
            sinceID: sinceID,
            limit: limit,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
    public func toggleBlock(
        account: Mastodon.Entity.Account,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        guard let relationship = try await relationship(forAccounts: [account], authenticationBox: authenticationBox).value.first else {
            throw APIError.implicit(.badRequest)
        }

        let response: Mastodon.Response.Content<Mastodon.Entity.Relationship>

        if relationship.blocking {
            response = try await Mastodon.API.Account.unblock(
                session: session,
                domain: authenticationBox.domain,
                accountID: account.id,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
        } else {
            response = try await Mastodon.API.Account.block(
                session: session,
                domain: authenticationBox.domain,
                accountID: account.id,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
        }

        return response
    }
}

extension MastodonUser {
    func deleteStatusAndNotificationFeeds(in context: NSManagedObjectContext) {
        statuses.map {
            $0.feeds
                .union($0.reblogFrom.map { $0.feeds }.flatMap { $0 })
                .union($0.notifications.map { $0.feeds }.flatMap { $0 })
        }
        .flatMap { $0 }
        .forEach(context.delete)
        
        notifications.map {
            $0.feeds
        }
        .flatMap { $0 }
        .forEach(context.delete)
    }
}
