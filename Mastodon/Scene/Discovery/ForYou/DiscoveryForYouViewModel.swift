//
//  DiscoveryForYouViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-14.
//

import os.log
import UIKit
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore

final class DiscoveryForYouViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let userFetchedResultsController: UserFetchedResultsController
    
    @MainActor
    @Published var familiarFollowers: [Mastodon.Entity.FamiliarFollowers] = []
    @Published var isFetching = false

    // output
    var diffableDataSource: UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.userFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: authContext.mastodonAuthenticationBox.domain,
            additionalPredicate: nil
        )
        // end init
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension DiscoveryForYouViewModel {
    
    @MainActor
    func fetch() async throws {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        
        do {
            let userIDs = try await fetchSuggestionAccounts()
            
            let _familiarFollowersResponse = try? await context.apiService.familiarFollowers(
                query: .init(ids: userIDs),
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            familiarFollowers = _familiarFollowersResponse?.value ?? []
            userFetchedResultsController.userIDs = userIDs
        } catch {
            // do nothing
        }
    }
    
    private func fetchSuggestionAccounts() async throws -> [Mastodon.Entity.Account.ID] {
        do {
            let response = try await context.apiService.suggestionAccountV2(
                query: nil,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            let userIDs = response.value.map { $0.account.id }
            return userIDs
        } catch {
            // fallback V1
            let response = try await context.apiService.suggestionAccount(
                query: nil,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            let userIDs = response.value.map { $0.id }
            return userIDs
        }
    }
}
