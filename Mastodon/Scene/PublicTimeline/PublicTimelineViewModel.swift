//
//  PublicTimelineViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import AlamofireImage
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import os.log
import UIKit

class PublicTimelineViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<Toot>
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    weak var tableView: UITableView?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, Item>?

    lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.LoadingMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    let tootIDs = CurrentValueSubject<[String], Never>([])
    let items = CurrentValueSubject<[Item], Never>([])
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    init(context: AppContext) {
        self.context = context
        self.fetchedResultsController = {
            let fetchRequest = Toot.sortedFetchRequest
            fetchRequest.predicate = Toot.predicate(domain: "", ids: [])
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
        
        items
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                os_log("%{public}s[%{public}ld], %{public}s: items did change", (#file as NSString).lastPathComponent, #line, #function)

                var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items)
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Idle, is State.LoadingMore, is State.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    default:
                        break
                    }
                }
                diffableDataSource.apply(snapshot, animatingDifferences: !items.isEmpty)
            }
            .store(in: &disposeBag)
        
        tootIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self = self else { return }
                let domain = self.context.authenticationService.activeMastodonAuthenticationBox.value?.domain ?? ""
                self.fetchedResultsController.fetchRequest.predicate = Toot.predicate(domain: domain, ids: ids)
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
    }
}

extension PublicTimelineViewModel {
    
    func loadMore() -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Toot]>, Error> {
        return context.apiService.publicTimeline(domain: "mstdn.jp")
    }
}
