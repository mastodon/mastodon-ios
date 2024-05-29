//
//  UserListViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import Combine
import CoreDataStack
import GameplayKit
import MastodonCore
import MastodonSDK

final class UserListViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let kind: Kind
    @Published var accounts: [Mastodon.Entity.Account]
    @Published var relationships: [Mastodon.Entity.Relationship]

    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>!
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
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

    public init(
        context: AppContext,
        authContext: AuthContext,
        kind: Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        self.accounts = []
        self.relationships = []
    }
}

extension UserListViewModel {
    // TODO: refactor follower and following into user list
    enum Kind {
        case rebloggedBy(status: MastodonStatus)
        case favoritedBy(status: MastodonStatus)
    }
}
