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
    let dataController: FeedDataController

    var presentedSuggestions = false

    @Published var lastAutomaticFetchTimestamp: Date? = nil
    @Published var scrollPositionRecord: ScrollPositionRecord? = nil
    @Published var displaySettingBarButtonItem = true
    @Published var hasPendingStatusEditReload = false
    let hasNewPosts = CurrentValueSubject<Bool, Never>(false)

    /// Becomes `true` if `networkErrorCount` is bigger than 5
    let isOffline = CurrentValueSubject<Bool, Never>(false)
    var networkErrorCount = CurrentValueSubject<Int, Never>(0)

    var timelineContext: MastodonFeed.Kind.TimelineContext = .home

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
            LoadLatestState.ContextSwitch(viewModel: self),
        ])
        stateMachine.enter(LoadLatestState.Initial.self)
        return stateMachine
    }()
    
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

    var cellFrameCache = NSCache<NSNumber, NSValue>()

    init(context: AppContext, authContext: AuthContext) {
        self.context  = context
        self.authContext = authContext
        self.dataController = FeedDataController(context: context, authContext: authContext)
        super.init()
        self.dataController.records = (try? FileManager.default.cachedHomeTimeline(for: authContext.mastodonAuthenticationBox).map {
            MastodonFeed.fromStatus($0, kind: .home)
        }) ?? []
        
        homeTimelineNeedRefresh
            .sink { [weak self] _ in
                self?.loadLatestStateMachine.enter(LoadLatestState.Loading.self)
            }
            .store(in: &disposeBag)
        self.dataController.$records
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] feeds in
                guard let self, self.timelineContext == .home else { return }

                let items: [MastodonStatus] = feeds.compactMap { feed -> MastodonStatus? in
                    guard let status = feed.status else { return nil }
                    return status
                }
                FileManager.default.cacheHomeTimeline(items: items, for: authContext.mastodonAuthenticationBox)
            })
            .store(in: &disposeBag)
        
        networkErrorCount
            .receive(on: DispatchQueue.main)
            .map { errorCount in
                return errorCount >= 5
            }
            .assign(to: \.value, on: isOffline)
            .store(in: &disposeBag)

        self.dataController.loadInitial(kind: .home(timeline: timelineContext))
    }

    func receiveLoadingStateCompletion(_ completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure:
            networkErrorCount.value = networkErrorCount.value + 1
        case .finished:
            networkErrorCount.value = 0
        }
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
        dataController.loadNext(kind: .home(timeline: timelineContext))
    }
}

extension HomeTimelineViewModel {

    // load timeline gap
    @MainActor
    func loadMore(item: StatusItem, at indexPath: IndexPath) async {
        guard case let .feedLoader(record) = item else { return }

        guard let status = record.status else { return }
        record.isLoadingMore = true

        await AuthenticationServiceProvider.shared.fetchAccounts(apiService: context.apiService)

        // fetch data
        let response: Mastodon.Response.Content<[Mastodon.Entity.Status]>?
        
        switch timelineContext {
        case .home:
            response = try? await context.apiService.homeTimeline(
               maxID: status.id,
               limit: 20,
               authenticationBox: authContext.mastodonAuthenticationBox
           )
        case .public:
            response = try? await context.apiService.publicTimeline(
                query: .init(maxID: status.id, limit: 20),
                authenticationBox: authContext.mastodonAuthenticationBox
            )
        }
        
        // insert missing items
        guard let items = response?.value else {
            record.isLoadingMore = false
            return
        }
        
        let firstIndex = indexPath.row
        let oldRecords = dataController.records
        let count = oldRecords.count
        let head = oldRecords[..<firstIndex]
        let tail = oldRecords[firstIndex..<count]
        
        var feedItems = [MastodonFeed]()
        
        /// See HomeTimelineViewModel+LoadLatestState.swift for the "Load More"-counterpart when fetching new timeline items
        for (index, item) in items.enumerated() {
            let hasMore: Bool
            
            /// there can only be a gap after the last items
            if index < items.count - 1 {
                hasMore = false
            } else {
                /// if fetched items and first item after gap don't match -> we got another gap
                if let entity = head.first?.status?.entity {
                    hasMore = item.id != entity.id
                } else {
                    hasMore = false
                }
            }

            feedItems.append(
                .fromStatus(item.asMastodonStatus, kind: .home, hasMore: hasMore)
            )
        }

        let combinedRecords = Array(head + feedItems + tail)
        dataController.records = combinedRecords
        
        record.isLoadingMore = false
        record.hasMore = false
    }
    
}

// MARK: - SuggestionAccountViewModelDelegate
extension HomeTimelineViewModel: SuggestionAccountViewModelDelegate {
    
}

