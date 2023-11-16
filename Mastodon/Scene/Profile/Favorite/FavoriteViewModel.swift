//
//  FavoriteViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-6.
//

import UIKit
import Combine
import GameplayKit
import MastodonCore
import MastodonSDK

final class FavoriteViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var records = [Mastodon.Entity.Status]()
    
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
    
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
    }
    
}
