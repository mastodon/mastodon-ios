//
//  ReportStatusViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import Combine
import CoreData
import CoreDataStack
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
    let account: Mastodon.Entity.Account
    let status: MastodonStatus?
    let dataController: StatusDataController

    @Published var isSkip = false
    @Published var selectStatuses = OrderedSet<MastodonStatus>()

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
    
    @MainActor
    init(
        context: AppContext,
        authContext: AuthContext,
        account: Mastodon.Entity.Account,
        status: MastodonStatus?
    ) {
        self.context = context
        self.authContext = authContext
        self.account = account
        self.status = status
        self.dataController = StatusDataController()
        // end init
        
        if let status = status {
            selectStatuses.append(status)
        }

        $selectStatuses
            .map { !$0.isEmpty }
            .assign(to: &$isNextButtonEnabled)
    }

}
