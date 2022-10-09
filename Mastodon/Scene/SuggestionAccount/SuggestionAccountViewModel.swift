//
//  SuggestionAccountViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import MastodonCore
import os.log
import UIKit
    
protocol SuggestionAccountViewModelDelegate: AnyObject {
    var homeTimelineNeedRefresh: PassthroughSubject<Void, Never> { get }
}

final class SuggestionAccountViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: SuggestionAccountViewModelDelegate?

    // input
    let context: AppContext
    let authContext: AuthContext
    let userFetchedResultsController: UserFetchedResultsController
    let selectedUserFetchedResultsController: UserFetchedResultsController
    
    var viewWillAppear = PassthroughSubject<Void, Never>()

    // output
    var collectionViewDiffableDataSource: UICollectionViewDiffableDataSource<SelectedAccountSection, SelectedAccountItem>?
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<RecommendAccountSection, RecommendAccountItem>?
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        self.userFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalPredicate: nil
        )
        self.selectedUserFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalPredicate: nil
        )
        super.init()
                
        userFetchedResultsController.domain = authContext.mastodonAuthenticationBox.domain
        selectedUserFetchedResultsController.domain = authContext.mastodonAuthenticationBox.domain
        selectedUserFetchedResultsController.additionalPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            MastodonUser.predicate(followingBy: authContext.mastodonAuthenticationBox.userID),
            MastodonUser.predicate(followRequestedBy: authContext.mastodonAuthenticationBox.userID)
        ])
    
        // fetch recomment users
        Task {
            var userIDs: [MastodonUser.ID] = []
            do {
                let response = try await context.apiService.suggestionAccountV2(
                    query: nil,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
                userIDs = response.value.map { $0.account.id }
            } catch let error as Mastodon.API.Error where error.httpResponseStatus == .notFound {
                let response = try await context.apiService.suggestionAccount(
                    query: nil,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
                userIDs = response.value.map { $0.id }
            } catch {
                os_log("%{public}s[%{public}ld], %{public}s: fetch recommendAccountV2 failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
            }
            
            guard !userIDs.isEmpty else { return }
            userFetchedResultsController.userIDs = userIDs
            selectedUserFetchedResultsController.userIDs = userIDs
        }
        
        // fetch relationship
        userFetchedResultsController.$records
            .removeDuplicates()
            .sink { [weak self] records in
                guard let _ = self else { return }
                Task {
                    _ = try await context.apiService.relationship(
                        records: records,
                        authenticationBox: authContext.mastodonAuthenticationBox
                    )
                }
            }
            .store(in: &disposeBag)
    }

}
