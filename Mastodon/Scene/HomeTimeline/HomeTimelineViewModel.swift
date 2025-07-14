//
//  HomeTimelineViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import AlamofireImage
import MastodonCore
import MastodonUI
import MastodonSDK

@MainActor
final class HomeTimelineViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let authenticationBox: MastodonAuthenticationBox
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
    var onPresentDonationCampaign = PassthroughSubject<Mastodon.Entity.DonationCampaign, Never>()

    var timelineContext: MastodonFeed.Kind.TimelineContext = .home {
        didSet {
            hasNewPosts.send(false)
        }
    }
    
    enum EmptyViewState {
        case timeline, list
    }

    weak var tableView: UITableView?
    weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    let timelineIsEmpty = CurrentValueSubject<EmptyViewState?, Never>(nil)
    let homeTimelineNeedRefresh = PassthroughSubject<Void, Never>()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, MastodonItemIdentifier>?
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

    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
        self.dataController = FeedDataController(authenticationBox: authenticationBox, kind: .home(timeline: timelineContext))
        super.init()
        let initialRecords = (try? PersistenceManager.shared.cached(.homeTimeline(authenticationBox)).map {
            MastodonFeed.fromStatus(MastodonStatus.fromEntity($0), kind: .home)
        }) ?? []
        Task {
            let lastRead = await BodegaPersistence.LastRead.lastReadMarkers(for: authenticationBox)
            await self.dataController.setRecordsAfterFiltering(initialRecords)
        }
        
        AuthenticationServiceProvider.shared.$didChangeFollowersAndFollowing.sink { [weak self] userID in
            guard self?.authenticationBox.globallyUniqueUserIdentifier == userID else { return }
            self?.homeTimelineNeedRefresh.send()
        }.store(in: &disposeBag)
        
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
                FileManager.default.cacheHomeTimeline(items: items, for: authenticationBox)
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
        case .failure(let error):
            if !(error is DecodingError) {
                networkErrorCount.value = networkErrorCount.value + 1
            }
        case .finished:
            networkErrorCount.value = 0
        }
    }
    
    func saveLastRead(_ tableView: UITableView) {
        guard timelineContext == .home else { return }
        let topVisibleIndexPath = tableView.indexPathsForVisibleRows?.sorted().first(where: { indexPath in
            switch diffableDataSource?.itemIdentifier(for: indexPath) {
            case .feed, .status:
                return true
            default:
                return false
            }
        })
        
        guard let topVisibleIndexPath, let topVisibleItem = diffableDataSource?.itemIdentifier(for: topVisibleIndexPath) else { return }
        
        let statusID: Mastodon.Entity.Status.ID
        switch topVisibleItem {
        case .status(let status):
            statusID = status.id
        case .feed(let feed):
            statusID = feed.id
        default:
            return
        }
        Task {
            let currentMarkers = await BodegaPersistence.LastRead.lastReadMarkers(for: authenticationBox) ?? LastReadMarkers(userGUID: authenticationBox.globallyUniqueUserIdentifier, home: nil, notifications: nil, mentions: nil)
            try await BodegaPersistence.LastRead.saveLastReadMarkers(currentMarkers.bySettingPosition(.local(lastReadID: statusID), forKind: .home, enforceForwardProgress: false), for: authenticationBox)
        }
    }
}

extension HomeTimelineViewModel {
    struct ScrollPositionRecord {
        let item: MastodonItemIdentifier
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
    func loadMore(item: MastodonItemIdentifier, at indexPath: IndexPath) async {
        guard case let .feedLoader(feedItem) = item else { return }

        guard let status = feedItem.status else { return }
        feedItem.isLoadingMore = true

        await AuthenticationServiceProvider.shared.fetchAccounts(onlyIfItHasBeenAwhile: true)

        // fetch data
        let response: Mastodon.Response.Content<[Mastodon.Entity.Status]>?
        
        switch timelineContext {
        case .home:
            response = try? await APIService.shared.homeTimeline(
               itemsImmediatelyBefore: status.id,
               authenticationBox: authenticationBox
           )
        case .public:
            response = try? await APIService.shared.publicTimeline(
                query: .init(local: true, maxID: status.id),
                authenticationBox: authenticationBox
            )
        case let .list(id):
            response = try? await APIService.shared.listTimeline(
                id: id,
                query: .init(local: true, maxID: status.id),
                authenticationBox: authenticationBox
            )
        case let .hashtag(tag):
            response = try? await APIService.shared.hashtagTimeline(
                hashtag: tag,
                authenticationBox: authenticationBox
            )
        }
        
        // insert missing items
        guard let items = response?.value else {
            feedItem.isLoadingMore = false
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
        
        Task {
            await dataController.setRecordsAfterFiltering(combinedRecords)
            
            feedItem.isLoadingMore = false
            feedItem.hasMore = false
        }
    }
    
}

// MARK: - SuggestionAccountViewModelDelegate
extension HomeTimelineViewModel: SuggestionAccountViewModelDelegate {
    
}

