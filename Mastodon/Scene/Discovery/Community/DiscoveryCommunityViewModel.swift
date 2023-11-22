//
//  DiscoveryCommunityViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-29.
//

import UIKit
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore

final class DiscoveryCommunityViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let viewDidAppeared = PassthroughSubject<Void, Never>()
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
    
    @MainActor
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.statusFetchedResultsController = StatusFetchedResultsController()
        // end init
    }
}
