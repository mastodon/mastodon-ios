//
//  DiscoveryPostsViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import UIKit
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore

final class DiscoveryPostsViewModel {
    
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
    
    let didLoadLatest = PassthroughSubject<Void, Never>()
    @Published var isServerSupportEndpoint = true
    
    @MainActor
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.dataController = StatusDataController()
        
        Task {
            await checkServerEndpoint()
        }   // end Task
    }
}

extension DiscoveryPostsViewModel {
    func checkServerEndpoint() async {
        do {
            _ = try await context.apiService.trendStatuses(
                domain: authContext.mastodonAuthenticationBox.domain,
                query: .init(offset: nil, limit: nil),
                authenticationBox: authContext.mastodonAuthenticationBox
            )
        } catch let error as Mastodon.API.Error where error.httpResponseStatus.code == 404 {
            isServerSupportEndpoint = false
        } catch {
            // do nothing
        }
    }
}
