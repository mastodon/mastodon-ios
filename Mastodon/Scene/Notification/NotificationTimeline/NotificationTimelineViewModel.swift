//
//  NotificationTimelineViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import GameplayKit
import MastodonSDK
import MastodonCore

final class NotificationTimelineViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let scope: Scope
//    let feedFetchedResultsController: FeedFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var isLoadingLatest = false
    @Published var lastAutomaticFetchTimestamp: Date?
    @Published var records = [Mastodon.Entity.Notification]()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<NotificationSection, NotificationItem>?
    var didLoadLatest = PassthroughSubject<Void, Never>()

    // bottom loader
    private(set) lazy var loadOldestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadOldestState.Initial(viewModel: self),
            LoadOldestState.Loading(viewModel: self),
            LoadOldestState.Fail(viewModel: self),
            LoadOldestState.Idle(viewModel: self),
            LoadOldestState.NoMore(viewModel: self),
        ])
        stateMachine.enter(LoadOldestState.Initial.self)
        return stateMachine
    }()
    
    init(
        context: AppContext,
        authContext: AuthContext,
        scope: Scope
    ) {
        self.context = context
        self.authContext = authContext
        self.scope = scope
//        self.feedFetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        // end init
        
//        feedFetchedResultsController.predicate = NotificationTimelineViewModel.feedPredicate(
//            authenticationBox: authContext.mastodonAuthenticationBox,
//            scope: scope
//        )
        
        loadNotifications(
            authenticationBox: authContext.mastodonAuthenticationBox,
            scope: scope
        )
    }
    
    
}

extension NotificationTimelineViewModel {

    typealias Scope = APIService.MastodonNotificationScope
    
    func loadNotifications(
        authenticationBox: MastodonAuthenticationBox,
        scope: Scope
    ) {
        Task {
            let notifications = try await context.apiService.notifications(
                maxID: nil,
                scope: scope,
                authenticationBox: authenticationBox
            ).value
            
            records = notifications
        }
    }
    
//    static func feedPredicate(
//        authenticationBox: MastodonAuthenticationBox,
//        scope: Scope
//    ) -> NSPredicate {
//        let domain = authenticationBox.domain
//        let userID = authenticationBox.userID
//        let acct = Feed.Acct.mastodon(
//            domain: domain,
//            userID: userID
//        )
//        
//        let predicate: NSPredicate = {
//            switch scope {
//            case .everything:
//                return NSCompoundPredicate(andPredicateWithSubpredicates: [
//                    Feed.hasNotificationPredicate(),
//                    Feed.predicate(
//                        kind: .notificationAll,
//                        acct: acct
//                    )
//                ])
//            case .mentions:
//                return NSCompoundPredicate(andPredicateWithSubpredicates: [
//                    Feed.hasNotificationPredicate(),
//                    Feed.predicate(
//                        kind: .notificationMentions,
//                        acct: acct
//                    ),
//                    Feed.notificationTypePredicate(types: scope.includeTypes ?? [])
//                ])
//            }
//        }()
//        return predicate
//    }

}

extension NotificationTimelineViewModel {
    
    // load lastest
    func loadLatest() async {
        isLoadingLatest = true
        defer { isLoadingLatest = false }
        
        do {
            _ = try await context.apiService.notifications(
                maxID: nil,
                scope: scope,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
        } catch {
            didLoadLatest.send()
        }
    }
    
    // load timeline gap
    func loadMore(item: NotificationItem) async {
        guard case let .feedLoader(record) = item, let notification = record.notification else { return }
        
//        let managedObjectContext = context.managedObjectContext
        let key = "LoadMore@\(notification.id)"
        
//        // return when already loading state
//        guard managedObjectContext.cache(froKey: key) == nil else { return }
//
//        guard let feed = record.object(in: managedObjectContext) else { return }
//        guard let maxID = feed.notification?.id else { return }
//        // keep transient property live
//        managedObjectContext.cache(feed, key: key)
//        defer {
//            managedObjectContext.cache(nil, key: key)
//        }
        
        // fetch data
        do {
            _ = try await context.apiService.notifications(
                maxID: notification.id,
                scope: scope,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
        } catch {
        }
    }
    
}
