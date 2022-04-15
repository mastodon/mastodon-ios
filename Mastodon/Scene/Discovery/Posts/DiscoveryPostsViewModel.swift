//
//  DiscoveryPostsViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import os.log
import UIKit
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import MastodonSDK

final class DiscoveryPostsViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let statusFetchedResultsController: StatusFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    let didLoadLatest = PassthroughSubject<Void, Never>()
    @Published var isServerSupportEndpoint = true
    
    init(context: AppContext) {
        self.context = context
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalTweetPredicate: nil
        )
        // end init
        
        context.authenticationService.activeMastodonAuthentication
            .map { $0?.domain }
            .assign(to: \.value, on: statusFetchedResultsController.domain)
            .store(in: &disposeBag)
        
        Task {
            await checkServerEndpoint()
        }   // end Task
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension DiscoveryPostsViewModel {
    func checkServerEndpoint() async {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        
        do {
            _ = try await context.apiService.trendStatuses(
                domain: authenticationBox.domain,
                query: .init(offset: nil, limit: nil)
            )
        } catch let error as Mastodon.API.Error where error.httpResponseStatus.code == 404 {
            isServerSupportEndpoint = false
        } catch {
            // do nothing
        }
    }
}
