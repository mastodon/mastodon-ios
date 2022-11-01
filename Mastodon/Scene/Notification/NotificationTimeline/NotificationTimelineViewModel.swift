//
//  NotificationTimelineViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import GameplayKit
import MastodonSDK
import MastodonCore

final class NotificationTimelineViewModel {
    
    let logger = Logger(subsystem: "NotificationTimelineViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let scope: Scope
    let feedFetchedResultsController: FeedFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var isLoadingLatest = false
    @Published var lastAutomaticFetchTimestamp: Date?
    
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
        self.feedFetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        // end init
        
        feedFetchedResultsController.predicate = NotificationTimelineViewModel.feedPredicate(
            authenticationBox: authContext.mastodonAuthenticationBox,
            scope: scope
        )
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension NotificationTimelineViewModel {

    typealias Scope = APIService.MastodonNotificationScope
    
    static func feedPredicate(
        authenticationBox: MastodonAuthenticationBox,
        scope: Scope
    ) -> NSPredicate {
        let domain = authenticationBox.domain
        let userID = authenticationBox.userID
        let acct = Feed.Acct.mastodon(
            domain: domain,
            userID: userID
        )
        
        let predicate: NSPredicate = {
            switch scope {
            case .everything:
                return NSCompoundPredicate(andPredicateWithSubpredicates: [
                    Feed.hasNotificationPredicate(),
                    Feed.predicate(
                        kind: .notificationAll,
                        acct: acct
                    )
                ])
            case .mentions:
                return NSCompoundPredicate(andPredicateWithSubpredicates: [
                    Feed.hasNotificationPredicate(),
                    Feed.predicate(
                        kind: .notificationMentions,
                        acct: acct
                    ),
                    Feed.notificationTypePredicate(types: scope.includeTypes ?? [])
                ])
            }
        }()
        return predicate
    }

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
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    
    // load timeline gap
    func loadMore(item: NotificationItem) async {
        guard case let .feedLoader(record) = item else { return }
        
        let managedObjectContext = context.managedObjectContext
        let key = "LoadMore@\(record.objectID)"
        
        // return when already loading state
        guard managedObjectContext.cache(froKey: key) == nil else { return }

        guard let feed = record.object(in: managedObjectContext) else { return }
        guard let maxID = feed.notification?.id else { return }
        // keep transient property live
        managedObjectContext.cache(feed, key: key)
        defer {
            managedObjectContext.cache(nil, key: key)
        }
        
        // fetch data
        do {
            _ = try await context.apiService.notifications(
                maxID: maxID,
                scope: scope,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch more failure: \(error.localizedDescription)")
        }
    }
    
}
