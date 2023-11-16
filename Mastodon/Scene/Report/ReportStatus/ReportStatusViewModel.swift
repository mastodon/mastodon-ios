//
//  ReportStatusViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import Combine
import Foundation
import GameplayKit
import MastodonSDK
import OrderedCollections
import UIKit
import MastodonCore

class ReportStatusViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    weak var delegate: ReportStatusViewControllerDelegate?
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let user: Mastodon.Entity.Account
    let status: Mastodon.Entity.Status?
//    let statusFetchedResultsController: StatusFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    @Published var isSkip = false
    @Published var selectStatuses = OrderedSet<Mastodon.Entity.Status>()
    @Published var records = [Mastodon.Entity.Status]()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ReportSection, ReportItem>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    @Published var isNextButtonEnabled = false
    
    init(
        context: AppContext,
        authContext: AuthContext,
        user: Mastodon.Entity.Account,
        status: Mastodon.Entity.Status?
    ) {
        self.context = context
        self.authContext = authContext
        self.user = user
        self.status = status
//        self.statusFetchedResultsController = StatusFetchedResultsController(
//            managedObjectContext: context.managedObjectContext,
//            domain: authContext.mastodonAuthenticationBox.domain,
//            additionalTweetPredicate: nil
//        )
        // end init
        
        if let status = status {
            selectStatuses.append(status)
        }

        $selectStatuses
            .map { !$0.isEmpty }
            .assign(to: &$isNextButtonEnabled)
    }

}
