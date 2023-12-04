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
        
        switch scope {
        case .everything:
            self.feedFetchedResultsController.records = (try? FileManager.default.cachedNotificationsAll(for: authContext.mastodonAuthenticationBox.userID))?.map({ notification in
                MastodonFeed.fromNotification(notification, kind: .notificationAll)
            }) ?? []
        case .mentions:
            self.feedFetchedResultsController.records = (try? FileManager.default.cachedNotificationsMentions(for: authContext.mastodonAuthenticationBox.userID))?.map({ notification in
                MastodonFeed.fromNotification(notification, kind: .notificationMentions)
            }) ?? []
        }
        
        self.feedFetchedResultsController.$records
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { feeds in
                let items: [Mastodon.Entity.Notification] = feeds.compactMap { feed -> Mastodon.Entity.Notification? in
                    guard let status = feed.notification else { return nil }
                    return status
                }
                switch self.scope {
                case .everything:
                    FileManager.default.cacheNotificationsAll(items: items, for: authContext.mastodonAuthenticationBox.userID)
                case .mentions:
                    FileManager.default.cacheNotificationsMentions(items: items, for: authContext.mastodonAuthenticationBox.userID)
                }
            })
            .store(in: &disposeBag)
    }
    
    
}

extension NotificationTimelineViewModel {

    typealias Scope = APIService.MastodonNotificationScope

}

extension NotificationTimelineViewModel {
    
    // load lastest
    func loadLatest() async {
        isLoadingLatest = true
        defer { isLoadingLatest = false }
        
        switch scope {
        case .everything:
            feedFetchedResultsController.loadInitial(kind: .notificationAll)
        case .mentions:
            feedFetchedResultsController.loadInitial(kind: .notificationMentions)
        }

        didLoadLatest.send()
    }
    
    // load timeline gap
    func loadMore(item: NotificationItem) async {
//        guard case let .feedLoader(record) = item else { return }

//        guard let maxID = record.notification?.id else { return }

//        // fetch data
//        if let notifications = try? await context.apiService.notifications(
//            maxID: maxID,
//            scope: scope,
//            authenticationBox: authContext.mastodonAuthenticationBox
//        ) {
//            self.feedFetchedResultsController.records += notifications.value.map { MastodonFeed.fromNotification($0, kind: record.kind) }
//        }
        switch scope {
        case .everything:
            feedFetchedResultsController.loadNext(kind: .notificationAll)
        case .mentions:
            feedFetchedResultsController.loadNext(kind: .notificationMentions)
        }
    }
}
