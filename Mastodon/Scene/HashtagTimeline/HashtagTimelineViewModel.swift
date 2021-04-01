//
//  HashtagTimelineViewModel.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
    
final class HashtagTimelineViewModel: NSObject {
    
    let hashTag: String
    
    var disposeBag = Set<AnyCancellable>()
    
    var hashtagStatusIDList = [Mastodon.Entity.Status.ID]()
    var needLoadMiddleIndex: Int? = nil
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<Toot>
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    let timelinePredicate = CurrentValueSubject<NSPredicate?, Never>(nil)

    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    
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
    private(set) lazy var loadoldestStateMachine: GKStateMachine = {
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

    
    init(context: AppContext, hashTag: String) {
        self.context  = context
        self.hashTag = hashTag
        self.fetchedResultsController = {
            let fetchRequest = Toot.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            return controller
        }()
        super.init()
        
        fetchedResultsController.delegate = self
        
        timelinePredicate
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
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
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
