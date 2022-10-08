//
//  DiscoveryNewsViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import os.log
import UIKit
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore

final class DiscoveryNewsViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    // output
    @Published var links: [Mastodon.Entity.Link] = []
    var diffableDataSource: UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem>?
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

    init(context: AppContext) {
        self.context = context
        // end init
        
        Task {
            await checkServerEndpoint()
        }   // end Task
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}


extension DiscoveryNewsViewModel {
    func checkServerEndpoint() async {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        
        do {
            _ = try await context.apiService.trendLinks(
                domain: authenticationBox.domain,
                query: .init(offset: nil, limit: nil)
            )
        } catch let error as Mastodon.API.Error where error.httpResponseStatus.code == 404 {
            isServerSupportEndpoint = false
        } catch {
            // do nothing
        }
    }
}
