//
//  DiscoveryForYouViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-14.
//

import UIKit
import Combine
import GameplayKit
import MastodonSDK
import MastodonCore

final class DiscoveryForYouViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext

    @MainActor
    @Published var familiarFollowers: [Mastodon.Entity.FamiliarFollowers] = []
    @Published var isFetching = false
    @Published var accounts: [Mastodon.Entity.Account]

    // output
    var diffableDataSource: UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.accounts = []
    }
}

extension DiscoveryForYouViewModel {
    
    @MainActor
    func fetch() async throws {
        guard isFetching == false else { return }
        isFetching = true
        defer { isFetching = false }
        
        do {
            let suggestedAccounts = try await fetchSuggestionAccounts()

            let familiarFollowersResponse = try? await context.apiService.familiarFollowers(
                query: .init(ids: suggestedAccounts.compactMap { $0.id }),
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value
            familiarFollowers = familiarFollowersResponse ?? []
            accounts = suggestedAccounts
        } catch {
            // do nothing
        }
    }
    
    private func fetchSuggestionAccounts() async throws -> [Mastodon.Entity.Account] {
        do {
            let response = try await context.apiService.suggestionAccountV2(
                query: nil,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value
            return response.compactMap { $0.account }
        } catch {
            // fallback V1
            let response = try await context.apiService.suggestionAccount(
                query: nil,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value

            return response
        }
    }
}
