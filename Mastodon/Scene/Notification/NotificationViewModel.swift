//
//  NotificationViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/12.
//

import Foundation
import Combine
import UIKit
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK

final class NotificationViewModel: NSObject  {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    weak var tableView: UITableView?
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    
    let viewDidLoad = PassthroughSubject<Void, Never>()
    let selectedIndex = CurrentValueSubject<Int,Never>(0)
    let noMoreNotification = CurrentValueSubject<Bool,Never>(false)
    
    let activeMastodonAuthenticationBox: CurrentValueSubject<AuthenticationService.MastodonAuthenticationBox?, Never>
    let fetchedResultsController: NSFetchedResultsController<MastodonNotification>!
    let notificationPredicate = CurrentValueSubject<NSPredicate?, Never>(nil)
    let cellFrameCache = NSCache<NSNumber, NSValue>()
    
    let isFetchingLatestNotification = CurrentValueSubject<Bool, Never>(false)
    
    //output
    var diffableDataSource: UITableViewDiffableDataSource<NotificationSection, NotificationItem>!
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
    
    init(context: AppContext) {
        self.context = context
        self.activeMastodonAuthenticationBox = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value)
        self.fetchedResultsController = {
            let fetchRequest = MastodonNotification.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.relationshipKeyPathsForPrefetching = [#keyPath(MastodonNotification.status),#keyPath(MastodonNotification.account)]
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        
        super.init()
        self.fetchedResultsController.delegate = self
        context.authenticationService.activeMastodonAuthenticationBox
            .sink(receiveValue: { [weak self] box in
                guard let self = self else { return }
                self.activeMastodonAuthenticationBox.value = box
                if let domain = box?.domain {
                    self.notificationPredicate.value = MastodonNotification.predicate(domain: domain)
                }
            })
            .store(in: &disposeBag)
        
        notificationPredicate
            .compactMap{ $0 }
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
        
        self.viewDidLoad
            .sink { [weak self] in
                
                guard let domain = self?.activeMastodonAuthenticationBox.value?.domain else { return }
                self?.notificationPredicate.value = MastodonNotification.predicate(domain: domain)
                
            }
            .store(in: &disposeBag)
    }
}
