//
//  HomeTimelineViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import func AVFoundation.AVMakeRect
import UIKit
import AVKit
import Combine
import GameplayKit
import AlamofireImage
import MastodonCore
import MastodonUI
import MastodonSDK

final class HomeTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
//    let fetchedResultsController: FeedFetchedResultsController
    let homeTimelineNavigationBarTitleViewModel: HomeTimelineNavigationBarTitleViewModel
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    var presentedSuggestions = false

    @Published var lastAutomaticFetchTimestamp: Date? = nil
    @Published var scrollPositionRecord: ScrollPositionRecord? = nil
    @Published var displaySettingBarButtonItem = true
    @Published var hasPendingStatusEditReload = false
    @Published var records = [Mastodon.Entity.Status]()
    
    weak var tableView: UITableView?
    weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    let timelineIsEmpty = CurrentValueSubject<Bool, Never>(false)
    let homeTimelineNeedRefresh = PassthroughSubject<Void, Never>()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()

    // top loader
    private(set) lazy var loadLatestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadLatestState.Initial(viewModel: self),
            LoadLatestState.Loading(viewModel: self),
            LoadLatestState.LoadingManually(viewModel: self),
            LoadLatestState.Fail(viewModel: self),
            LoadLatestState.Idle(viewModel: self),
        ])
        stateMachine.enter(LoadLatestState.Initial.self)
        return stateMachine
    }()
    lazy var loadLatestStateMachinePublisher = CurrentValueSubject<LoadLatestState?, Never>(nil)
    
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
    lazy var loadOldestStateMachinePublisher = CurrentValueSubject<LoadOldestState?, Never>(nil)

    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    init(context: AppContext, authContext: AuthContext) {
        self.context  = context
        self.authContext = authContext
//        self.fetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        self.homeTimelineNavigationBarTitleViewModel = HomeTimelineNavigationBarTitleViewModel(context: context)
        super.init()
        
//        fetchedResultsController.predicate = Feed.predicate(
//            kind: .home,
//            acct: .mastodon(domain: authContext.mastodonAuthenticationBox.domain, userID: authContext.mastodonAuthenticationBox.userID)
//        )
        
        Task {
            records = try await context.apiService.homeTimeline(authenticationBox: authContext.mastodonAuthenticationBox)
                .value
        }
        
        homeTimelineNeedRefresh
            .sink { [weak self] _ in
                self?.loadLatestStateMachine.enter(LoadLatestState.Loading.self)
            }
            .store(in: &disposeBag)

        // refresh after publish post
        homeTimelineNavigationBarTitleViewModel.isPublished
            .delay(for: 2, scheduler: DispatchQueue.main)
            .sink { [weak self] isPublished in
                guard let self = self else { return }
                self.homeTimelineNeedRefresh.send()
            }
            .store(in: &disposeBag)
    }
}

extension HomeTimelineViewModel {
    struct ScrollPositionRecord {
        let item: StatusItem
        let offset: CGFloat
        let timestamp: Date
    }
}

extension HomeTimelineViewModel {
    func timelineDidReachEnd() {
//        fetchedResultsController.fetchNextBatch()
        Task {
            let newRecords = try await context.apiService.homeTimeline(
                sinceID: records.last?.id,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value
            
            records += newRecords
        }
    }
}

extension HomeTimelineViewModel {

    // load timeline gap
    func loadMore(item: StatusItem) async {
        guard case let .feedLoader(record) = item, let status = record.status else { return }
        guard let diffableDataSource = diffableDataSource else { return }
        var snapshot = diffableDataSource.snapshot()
        
//        let managedObjectContext = context.managedObjectContext
        let key = "LoadMore@\(status.id)"
        
//        guard let feed = record.object(in: managedObjectContext) else { return }
//        guard let status = feed.status else { return }
        
//         keep transient property live
//        managedObjectContext.cache(feed, key: key)
//        defer {
//            managedObjectContext.cache(nil, key: key)
//        }
//        do {
//            // update state
//            try await managedObjectContext.performChanges {
//                feed.update(isLoadingMore: true)
//            }
//        } catch {
//            assertionFailure(error.localizedDescription)
//        }
        
        // reconfigure item
        snapshot.reconfigureItems([item])
        await updateSnapshotUsingReloadData(snapshot: snapshot)
        
        // fetch data
        do {
            let maxID = status.id
            _ = try await context.apiService.homeTimeline(
                maxID: maxID,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
        } catch {
//            do {
//                // restore state
//                try await managedObjectContext.performChanges {
//                    feed.update(isLoadingMore: false)
//                }
//            } catch {
//                assertionFailure(error.localizedDescription)
//            }
        }
        
        // reconfigure item again
        snapshot.reconfigureItems([item])
        await updateSnapshotUsingReloadData(snapshot: snapshot)
    }
    
}

// MARK: - SuggestionAccountViewModelDelegate
extension HomeTimelineViewModel: SuggestionAccountViewModelDelegate {
    
}

