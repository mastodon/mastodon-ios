//
//  SearchResultViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import CommonOSLog
import MastodonSDK
import MastodonCore

final class SearchResultViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let searchScope: SearchDetailViewModel.SearchScope
    let searchText = CurrentValueSubject<String, Never>("")
    @Published var hashtags: [Mastodon.Entity.Tag] = []
    let userFetchedResultsController: UserFetchedResultsController
    let statusFetchedResultsController: StatusFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    var navigationBarFrame = CurrentValueSubject<CGRect, Never>(.zero)

    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchResultSection, SearchResultItem>!
    @Published var items: [SearchResultItem] = []
    
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    let didDataSourceUpdate = PassthroughSubject<Void, Never>()

    init(context: AppContext, authContext: AuthContext, searchScope: SearchDetailViewModel.SearchScope) {
        self.context = context
        self.authContext = authContext
        self.searchScope = searchScope
        self.userFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: authContext.mastodonAuthenticationBox.domain,
            additionalPredicate: nil
        )
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: authContext.mastodonAuthenticationBox.domain,
            additionalTweetPredicate: nil
        )
    }

}
