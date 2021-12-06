//
//  FollowingListViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-2.
//

import Foundation
import Combine
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK

final class FollowingListViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let domain: CurrentValueSubject<String?, Never>
    let userID: CurrentValueSubject<String?, Never>
    let userFetchedResultsController: UserFetchedResultsController
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>?
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
    
    init(context: AppContext, domain: String?, userID: String?) {
        self.context = context
        self.userFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: domain,
            additionalTweetPredicate: nil
        )
        self.domain = CurrentValueSubject(domain)
        self.userID = CurrentValueSubject(userID)
        // super.init()
        
    }
}
