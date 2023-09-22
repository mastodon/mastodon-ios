//
//  DiscoveryHashtagsViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK

final class DiscoveryHashtagsViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let viewDidAppeared = PassthroughSubject<Void, Never>()

    // output
    var diffableDataSource: UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem>?
    @Published var hashtags: [Mastodon.Entity.Tag] = []
    
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        // end init
        
        viewDidAppeared
            .throttle(for: 3, scheduler: DispatchQueue.main, latest: true)
            .asyncMap { _ in
                let authenticationBox = authContext.mastodonAuthenticationBox
                return try await context.apiService.trendHashtags(domain: authenticationBox.domain,
                                                                  query: nil,
                                                                  authenticationBox: authenticationBox
                )
            }
            .retry(3)
            .map { response in Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { response } }
            .catch { error in Just(Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { throw error }) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                    case .success(let response):
                        self.hashtags = response.value.filter { !$0.name.isEmpty }
                    case .failure:
                        break
                }
            }
            .store(in: &disposeBag)
    }
}

extension DiscoveryHashtagsViewModel {
    
    @MainActor
    func fetch() async throws {

        let authenticationBox = authContext.mastodonAuthenticationBox
        let response = try await context.apiService.trendHashtags(domain: authenticationBox.domain,
                                                                  query: nil,
                                                                  authenticationBox: authenticationBox
        )
        hashtags = response.value.filter { !$0.name.isEmpty }
    }
    
}
