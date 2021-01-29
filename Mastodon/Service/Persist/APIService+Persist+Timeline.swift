//
//  APIService+Persist+Timeline.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.Persist {
    enum PersistTimelineType {
        case publicHomeTimeline
    }
    static func persistTimeline(
        domain: String,
        managedObjectContext: NSManagedObjectContext,
        response: Mastodon.Response.Content<[Mastodon.Entity.Toot]>,
        persistType: PersistTimelineType
    ) -> AnyPublisher<Result<Void, Error>, Never> {
        return managedObjectContext.performChanges {
            let toots = response.value
            let _ = toots.map {
                let userProperty = MastodonUser.Property(id: $0.account.id, domain: domain, acct: $0.account.acct, username: $0.account.username, displayName: $0.account.displayName,avatar: $0.account.avatar,avatarStatic: $0.account.avatarStatic, createdAt: $0.createdAt, networkDate: $0.createdAt)
                let author = MastodonUser.insert(into: managedObjectContext, property: userProperty)
                let tootProperty = Toot.Property(id: $0.id, domain: domain, content: $0.content, createdAt: $0.createdAt, networkDate: $0.createdAt)
                Toot.insert(into: managedObjectContext, property: tootProperty, author: author)
            }
        }.eraseToAnyPublisher()
    }
}
