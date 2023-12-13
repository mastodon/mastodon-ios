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
import CoreData
import CoreDataStack
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
    let fetchedResultsController: FeedFetchedResultsController
    let homeTimelineNavigationBarTitleViewModel: HomeTimelineNavigationBarTitleViewModel
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    var presentedSuggestions = false

    @Published var lastAutomaticFetchTimestamp: Date? = nil
    @Published var scrollPositionRecord: ScrollPositionRecord? = nil
    @Published var displaySettingBarButtonItem = true
    @Published var hasPendingStatusEditReload = false
    
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
        self.fetchedResultsController = FeedFetchedResultsController(context: context, authContext: authContext)
        self.homeTimelineNavigationBarTitleViewModel = HomeTimelineNavigationBarTitleViewModel(context: context)
        super.init()
        self.fetchedResultsController.records = (try? FileManager.default.cachedHomeTimeline(for: authContext.mastodonAuthenticationBox).map {
            MastodonFeed.fromStatus($0, kind: .home)
        }) ?? []
        
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
        
        self.fetchedResultsController.$records
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { feeds in
                let items: [MastodonStatus] = feeds.compactMap { feed -> MastodonStatus? in
                    guard let status = feed.status else { return nil }
                    return status
                }
                FileManager.default.cacheHomeTimeline(items: items, for: authContext.mastodonAuthenticationBox)
            })
            .store(in: &disposeBag)
        
        self.fetchedResultsController.loadInitial(kind: .home)
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
        fetchedResultsController.loadNext(kind: .home)
    }
}

extension HomeTimelineViewModel {

    // load timeline gap
    func loadMore(item: StatusItem) async {
        guard case let .feedLoader(record) = item else { return }
        guard let diffableDataSource = diffableDataSource else { return }
        var snapshot = diffableDataSource.snapshot()

        guard let status = record.status else { return }
        record.isLoadingMore = true

        // reconfigure item
        snapshot.reconfigureItems([item])
        await updateSnapshotUsingReloadData(snapshot: snapshot)

        await AuthenticationServiceProvider.shared.fetchAccounts(apiService: context.apiService)

        // fetch data
        let maxID = status.id
        _ = try? await context.apiService.homeTimeline(
            maxID: maxID,
            authenticationBox: authContext.mastodonAuthenticationBox
        )
        
        record.isLoadingMore = false
        
        // reconfigure item again
        snapshot.reconfigureItems([item])
        await updateSnapshotUsingReloadData(snapshot: snapshot)
    }
    
}

// MARK: - SuggestionAccountViewModelDelegate
extension HomeTimelineViewModel: SuggestionAccountViewModelDelegate {
    
}

