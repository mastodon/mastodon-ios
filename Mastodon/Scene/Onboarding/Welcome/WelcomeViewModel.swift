//
//  WelcomeViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import Foundation
import Combine
import MastodonCore
import MastodonSDK

final class WelcomeViewModel {
 
    var disposeBag = Set<AnyCancellable>()
    private(set) var defaultServers: [Mastodon.Entity.DefaultServer]?
    var randomDefaultServer: Mastodon.Entity.Server?

    // input
    let context: AppContext
    
    // output
    @Published var needsShowDismissEntry = false
    
    init(context: AppContext) {
        self.context = context
        
        context.authenticationService.$mastodonAuthenticationBoxes
            .map { !$0.isEmpty }
            .assign(to: &$needsShowDismissEntry)
    }

    func downloadDefaultServer(completion: (() -> Void)? = nil) {
            context.apiService.defaultServers()
            .timeout(.milliseconds(500) , scheduler: DispatchQueue.main)
            .sink { [weak self] result in

                switch result {
                case .finished:
                    if let defaultServers = self?.defaultServers, defaultServers.isEmpty == false {
                        self?.randomDefaultServer = self?.pickRandomDefaultServer()
                    } else {
                        self?.randomDefaultServer = Mastodon.Entity.Server.mastodonDotSocial
                    }
                case .failure(_):
                    self?.randomDefaultServer = Mastodon.Entity.Server.mastodonDotSocial
                }

                completion?()
            } receiveValue: { [weak self] servers in
                self?.defaultServers = servers.value
            }
            .store(in: &disposeBag)
    }

    func pickRandomDefaultServer() -> Mastodon.Entity.Server? {
        guard let defaultServers else { return nil }

        let weightedServers = defaultServers
            .compactMap { [Mastodon.Entity.DefaultServer](repeating: $0, count: $0.weight) }
            .reduce([], +)

        let randomServer = weightedServers.randomElement()
            .map { Mastodon.Entity.Server(domain: $0.domain, instance: Mastodon.Entity.Instance(domain: $0.domain)) }

        return randomServer
    }
}
