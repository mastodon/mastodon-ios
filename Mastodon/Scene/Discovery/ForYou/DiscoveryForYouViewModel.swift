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

final class DiscoveryForYouViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let userFetchedResultsController: UserFetchedResultsController
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
    func fetch() async throws {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        
        do {
            let response = try await context.apiService.suggestionAccountV2(
                query: nil,
                authenticationBox: authenticationBox
            )
            let userIDs = response.value.map { $0.account.id }
            userFetchedResultsController.userIDs = userIDs
        } catch {
            // fallback V1
            let response2 = try await context.apiService.suggestionAccount(
                query: nil,
                authenticationBox: authenticationBox
            )
            let userIDs = response2.value.map { $0.id }
            userFetchedResultsController.userIDs = userIDs
        }
    }
}
