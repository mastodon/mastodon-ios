//
//  SearchResultViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import Foundation
import Combine
import GameplayKit
import MastodonSDK
import MastodonCore

final class SearchResultViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let authenticationBox: MastodonAuthenticationBox
    let searchScope: SearchScope
    let searchText: String
    @Published var hashtags: [Mastodon.Entity.Tag] = []
    @Published var accounts: [Mastodon.Entity.Account] = []
    var relationships: [Mastodon.Entity.Relationship] = []
    let dataController: StatusDataController

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
        return stateMachine
    }()
    let didDataSourceUpdate = PassthroughSubject<Void, Never>()

    @MainActor
    init(authenticationBox: MastodonAuthenticationBox, searchScope: SearchScope = .all, searchText: String) {
        self.authenticationBox = authenticationBox
        self.searchScope = searchScope
        self.searchText = searchText
        self.accounts = []
        self.relationships = []

        self.dataController = StatusDataController()
    }
}
