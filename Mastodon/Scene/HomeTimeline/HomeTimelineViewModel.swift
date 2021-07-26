//
//  HomeTimelineViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import AlamofireImage
import DateToolsSwift

final class HomeTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let context: AppContext
    let timelinePredicate = CurrentValueSubject<NSPredicate?, Never>(nil)
    let fetchedResultsController: NSFetchedResultsController<HomeTimelineIndex>
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    let viewDidAppear = PassthroughSubject<Void, Never>()
    let homeTimelineNavigationBarTitleViewModel: HomeTimelineNavigationBarTitleViewModel
    
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    let timelineIsEmpty = CurrentValueSubject<Bool, Never>(false)
    let homeTimelineNeedRefresh = PassthroughSubject<Void, Never>()
    
    // output
    // top loader
    private(set) lazy var loadLatestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadLatestState.Initial(viewModel: self),
            LoadLatestState.Loading(viewModel: self),
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
    // middle loader
    let loadMiddleSateMachineList = CurrentValueSubject<[NSManagedObjectID: GKStateMachine], Never>([:])    // TimelineIndex.objectID : middle loading state machine
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>?
    var cellFrameCache = NSCache<NSNumber, NSValue>()

    
    init(context: AppContext) {
        self.context  = context
        self.fetchedResultsController = {
            let fetchRequest = HomeTimelineIndex.sortedFetchRequest
            fetchRequest.fetchBatchSize = 20
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.relationshipKeyPathsForPrefetching = [
                #keyPath(HomeTimelineIndex.status),
                #keyPath(HomeTimelineIndex.status.author),
                #keyPath(HomeTimelineIndex.status.reblog),
                #keyPath(HomeTimelineIndex.status.reblog.author),
            ]
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        self.homeTimelineNavigationBarTitleViewModel = HomeTimelineNavigationBarTitleViewModel(context: context)
        super.init()
        
        fetchedResultsController.delegate = self
        
        timelinePredicate
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .first()    // set once
            .sink { [weak self] predicate in
                guard let self = self else { return }
                self.fetchedResultsController.fetchRequest.predicate = predicate
                do {
                    self.diffableDataSource?.defaultRowAnimation = .fade
                    try self.fetchedResultsController.performFetch()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                        guard let self = self else { return }
                        self.diffableDataSource?.defaultRowAnimation = .automatic
                    }
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
        
        context.authenticationService.activeMastodonAuthentication
            .sink { [weak self] activeMastodonAuthentication in
                guard let self = self else { return }
                guard let mastodonAuthentication = activeMastodonAuthentication else { return }
                let domain = mastodonAuthentication.domain
                let userID = mastodonAuthentication.userID
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    HomeTimelineIndex.predicate(domain: domain, userID: userID),
                    HomeTimelineIndex.notDeleted()
                ])
                self.timelinePredicate.value = predicate
            }
            .store(in: &disposeBag)
        
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
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension HomeTimelineViewModel: SuggestionAccountViewModelDelegate { }
