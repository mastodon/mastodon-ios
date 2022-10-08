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
    let userFetchedResultsController: UserFetchedResultsController
    
    @MainActor
    @Published var familiarFollowers: [Mastodon.Entity.FamiliarFollowers] = []
    @Published var isFetching = false

    // output
    var diffableDataSource: UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    init(context: AppContext) {
        self.context = context
        self.userFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalPredicate: nil
        )
        // end init
        
        context.authenticationService.activeMastodonAuthenticationBox
            .map { $0?.domain }
            .assign(to: \.domain, on: userFetchedResultsController)
            .store(in: &disposeBag)
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
        
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            throw APIService.APIError.implicit(.badRequest)
        }
        
        do {
            let userIDs = try await fetchSuggestionAccounts()
            
            let _familiarFollowersResponse = try? await context.apiService.familiarFollowers(
                query: .init(ids: userIDs),
                authenticationBox: authenticationBox
            )
            familiarFollowers = _familiarFollowersResponse?.value ?? []
            userFetchedResultsController.userIDs = userIDs
        } catch {
            // do nothing
        }
    }
    
    private func fetchSuggestionAccounts() async throws -> [Mastodon.Entity.Account.ID] {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            throw APIService.APIError.implicit(.badRequest)
        }
        
        do {
            let response = try await context.apiService.suggestionAccountV2(
                query: nil,
                authenticationBox: authenticationBox
            )
            let userIDs = response.value.map { $0.account.id }
            return userIDs
        } catch {
            // fallback V1
            let response = try await context.apiService.suggestionAccount(
                query: nil,
                authenticationBox: authenticationBox
            )
            let userIDs = response.value.map { $0.id }
            return userIDs
        }
    }
}
