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
    var relationships: [Mastodon.Entity.Relationship?]

    // output
    var diffableDataSource: UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.accounts = []
        self.relationships = []
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

            let relationships = try? await context.apiService.relationship(
                forAccounts: suggestedAccounts,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value

            familiarFollowers = familiarFollowersResponse ?? []
            accounts = suggestedAccounts
            self.relationships = relationships ?? []
        } catch {
            // do nothing
        }

        await MainActor.run {
            guard let diffableDataSource = self.diffableDataSource else { return }

            var snapshot = NSDiffableDataSourceSnapshot<DiscoverySection, DiscoveryItem>()
            snapshot.appendSections([.forYou])

            let items = self.accounts.map { account in
                let relationship = relationships.first { $0?.id == account.id } ?? nil

                return DiscoveryItem.account(account, relationship: relationship)
            }
            
            snapshot.appendItems(items, toSection: .forYou)

            diffableDataSource.apply(snapshot, animatingDifferences: false)
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
