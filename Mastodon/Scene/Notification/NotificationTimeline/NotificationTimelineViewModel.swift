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

final class NotificationTimelineViewModel {
    
    let logger = Logger(subsystem: "NotificationTimelineViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let scope: Scope
    let feedFetchedResultsController: FeedFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

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
        scope: Scope
    ) {
        self.context = context
        self.scope = scope
        self.feedFetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        // end init
        
        context.authenticationService.activeMastodonAuthenticationBox
            .sink { [weak self] authenticationBox in
                guard let self = self else { return }
                guard let authenticationBox = authenticationBox else {
                    self.feedFetchedResultsController.predicate = Feed.nonePredicate()
                    return
                }
                
                let predicate = NotificationTimelineViewModel.feedPredicate(
                    authenticationBox: authenticationBox,
                    scope: scope
                )
                self.feedFetchedResultsController.predicate = predicate
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension NotificationTimelineViewModel {
    enum Scope: Hashable, CaseIterable {
        case everything
        case mentions
        
        var includeTypes: [MastodonNotificationType]? {
            switch self {
            case .everything:       return nil
            case .mentions:         return [.mention, .status]
            }
        }
        
        
        var excludeTypes: [MastodonNotificationType]? {
            switch self {
            case .everything:       return nil
            case .mentions:         return [.follow, .followRequest, .reblog, .favourite, .poll]
            }
        }
        
        var _excludeTypes: [Mastodon.Entity.Notification.NotificationType]? {
            switch self {
            case .everything:       return nil
            case .mentions:         return [.follow, .followRequest, .reblog, .favourite, .poll]
            }
        }
    }
    
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
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        do {
            _ = try await context.apiService.notifications(
                maxID: nil,
                scope: scope,
                authenticationBox: authenticationBox
            )
        } catch {
            didLoadLatest.send()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    
}
