//
//  UserTimelineViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore

final class UserTimelineViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let title: String
    let dataController: StatusDataController
    @Published var userIdentifier: UserIdentifier?
    @Published var queryFilter: QueryFilter

    @Published var isBlocking = false
    @Published var isDomainBlocking = false
    @Published var isBlockedBy = false
    @Published var isSuspended = false

    // let userDisplayName = CurrentValueSubject<String?, Never>(nil)  // for suspended prompt label
    // var dataSourceDidUpdate = PassthroughSubject<Void, Never>()

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
    init(
        context: AppContext,
        authContext: AuthContext,
        title: String,
        queryFilter: QueryFilter
    ) {
        self.context = context
        self.authContext = authContext
        self.title = title
        self.dataController = StatusDataController()
        self.queryFilter = queryFilter
    }
}

extension UserTimelineViewModel {
    struct QueryFilter {
        let excludeReplies: Bool?
        let excludeReblogs: Bool?
        let onlyMedia: Bool?
        
        init(
            excludeReplies: Bool? = nil,
            excludeReblogs: Bool? = nil,
            onlyMedia: Bool? = nil
        ) {
            self.excludeReplies = excludeReplies
            self.excludeReblogs = excludeReblogs
            self.onlyMedia = onlyMedia
        }
    }
}
