//
//  DataSourceFacade+SearchHistory.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import Foundation
import CoreDataStack
import MastodonCore

extension DataSourceFacade {
    
    static func responseToCreateSearchHistory(
        provider: DataSourceProvider & AuthContextProvider,
        item: DataSourceItem
    ) async {
        switch item {
        case .status:
            break       // not create search history for status
        case .user(let record):
            let authenticationBox = provider.authContext.mastodonAuthenticationBox
            let managedObjectContext = provider.context.backgroundManagedObjectContext
            
            try? await managedObjectContext.performChanges {
                guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else { return }
                guard let user = record.object(in: managedObjectContext) else { return }
                _ = Persistence.SearchHistory.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.SearchHistory.PersistContext(
                        entity: .user(user),
                        me: me,
                        now: Date()
                    )
                )
            }   // end try? await managedObjectContext.performChanges { … }
        case .hashtag(let tag):
            let authenticationBox = provider.authContext.mastodonAuthenticationBox
            let managedObjectContext = provider.context.backgroundManagedObjectContext

            switch tag {
            case .entity(let entity):
                try? await managedObjectContext.performChanges {
                    guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else { return }
                    
                    let now = Date()
                    
                    let result = Persistence.Tag.createOrMerge(
                        in: managedObjectContext,
                        context: Persistence.Tag.PersistContext(
                            domain: authenticationBox.domain,
                            entity: entity,
                            me: me,
                            networkDate: now
                        )
                    )
                    
                    _ = Persistence.SearchHistory.createOrMerge(
                        in: managedObjectContext,
                        context: Persistence.SearchHistory.PersistContext(
                            entity: .hashtag(result.tag),
                            me: me,
                            now: now
                        )
                    )
                }   // end try? await managedObjectContext.performChanges { … }
            case .record(let record):
                try? await managedObjectContext.performChanges {
                    let authenticationBox = provider.authContext.mastodonAuthenticationBox
                    guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else { return }
                    guard let tag = record.object(in: managedObjectContext) else { return }
                    
                    let now = Date()

                    _ = Persistence.SearchHistory.createOrMerge(
                        in: managedObjectContext,
                        context: Persistence.SearchHistory.PersistContext(
                            entity: .hashtag(tag),
                            me: me,
                            now: now
                        )
                    )
                }   // end try? await managedObjectContext.performChanges { … }
            }   // end switch tag { … }
        case .notification:
            assertionFailure()
        }   // end switch item { … }
    }   // end func
    
}

extension DataSourceFacade {
    
    static func responseToDeleteSearchHistory(
        provider: DataSourceProvider & AuthContextProvider
    ) async throws {
        let authenticationBox = provider.authContext.mastodonAuthenticationBox
        let managedObjectContext = provider.context.backgroundManagedObjectContext
        
        try await managedObjectContext.performChanges {
            guard let _ = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else { return }
            let request = SearchHistory.sortedFetchRequest
            request.predicate = SearchHistory.predicate(
                domain: authenticationBox.domain,
                userID: authenticationBox.userID
            )
            let searchHistories = managedObjectContext.safeFetch(request)
            
            for searchHistory in searchHistories {
                managedObjectContext.delete(searchHistory)
            }
        }   // end try await managedObjectContext.performChanges { … }
    }   // end func

}
