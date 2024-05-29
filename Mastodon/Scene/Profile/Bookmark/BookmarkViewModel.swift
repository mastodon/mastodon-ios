//
//  BookmarkViewModel.swift
//  Mastodon
//
//  Created by ProtoLimit on 2022-07-19.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonCore

final class BookmarkViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    
    let dataController: StatusDataController

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
    
    @MainActor
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.dataController = StatusDataController()
    }
    
}
