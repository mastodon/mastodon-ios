//
//  DiscoveryForYouViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-14.
//

import UIKit
import Combine
import MastodonSDK
import MastodonCore

final class DiscoveryForYouViewModel {
    // input
    let authenticationBox: MastodonAuthenticationBox

    @MainActor
    @Published var familiarFollowers: [Mastodon.Entity.FamiliarFollowers] = []
    @Published var isFetching = false
    @Published var accounts: [Mastodon.Entity.Account]
    var relationships: [Mastodon.Entity.Relationship]

    // output
    var diffableDataSource: UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
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

            let familiarFollowersResponse = try? await APIService.shared.familiarFollowers(
                query: .init(ids: suggestedAccounts.compactMap { $0.id }),
                authenticationBox: authenticationBox
            ).value

            let relationships = try? await APIService.shared.relationship(
                forAccounts: suggestedAccounts,
                authenticationBox: authenticationBox
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
                let relationship = relationships.first { $0.id == account.id } ?? nil

                return DiscoveryItem.account(account, relationship: relationship)
            }
            
            snapshot.appendItems(items, toSection: .forYou)

            diffableDataSource.apply(snapshot, animatingDifferences: false)
        }
    }
    
    private func fetchSuggestionAccounts() async throws -> [Mastodon.Entity.Account] {
        do {
            let response = try await APIService.shared.suggestionAccountV2(
                query: nil,
                authenticationBox: authenticationBox
            ).value
            return response.compactMap { $0.account }
        } catch {
            // fallback V1
            let response = try await APIService.shared.suggestionAccount(
                query: nil,
                authenticationBox: authenticationBox
            ).value

            return response
        }
    }
}
