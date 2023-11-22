//
//  NotificationTimelineViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import CoreDataStack
import GameplayKit
import MastodonSDK
import MastodonCore

final class NotificationTimelineViewModel {
    
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
    
    @MainActor
    init(
        context: AppContext,
        authContext: AuthContext,
        scope: Scope
    ) {
        self.context = context
        self.authContext = authContext
        self.scope = scope
        self.feedFetchedResultsController = FeedFetchedResultsController(context: context, authContext: authContext)
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
        }
    }
    
    // load timeline gap
    func loadMore(item: NotificationItem) async {
        guard case let .feedLoader(record) = item else { return }

        guard let maxID = record.notification?.id else { return }

        // fetch data
        if let notifications = try? await context.apiService.notifications(
            maxID: maxID,
            scope: scope,
            authenticationBox: authContext.mastodonAuthenticationBox
        ) {
            self.feedFetchedResultsController.records += notifications.value.map { MastodonFeed.fromNotification($0, kind: record.kind) }
        }
    }
    
}
