//
//  DiscoveryNewsViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import Combine
import GameplayKit
import CoreData // needed until DiscoveryForYouViewController is replaced
import CoreDataStack // needed until DiscoveryForYouViewController is replaced
import MastodonSDK
import MastodonCore

final class DiscoveryNewsViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let authenticationBox: MastodonAuthenticationBox

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

    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
        // end init
        
        Task {
            await checkServerEndpoint()
        }   // end Task
    }
}


extension DiscoveryNewsViewModel {
    func checkServerEndpoint() async {
        do {
            _ = try await APIService.shared.trendLinks(
                domain: authenticationBox.domain,
                query: .init(offset: nil, limit: nil),
                authenticationBox: authenticationBox
            )
        } catch let error as Mastodon.API.Error where error.httpResponseStatus?.code == 404 {
            isServerSupportEndpoint = false
        } catch {
            // do nothing
        }
    }
}
