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

    var viewWillAppear = PassthroughSubject<Void, Never>()

    // output
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
        super.init()
                
        userFetchedResultsController.domain = authContext.mastodonAuthenticationBox.domain

        // fetch recomment users
        Task {
            var userIDs: [MastodonUser.ID] = []
            do {
                let response = try await context.apiService.suggestionAccountV2(
                    query: .init(limit: 5),
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
                
            }
            
            guard !userIDs.isEmpty else { return }
            userFetchedResultsController.userIDs = userIDs
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

    func followAllSuggestedAccounts(_ dependency: NeedsDependency & AuthContextProvider ) {

        let userRecords = userFetchedResultsController.records.compactMap {
            $0.object(in: dependency.context.managedObjectContext)?.asRecord
        }

        userRecords.forEach { user in
            Task {
                try? await DataSourceFacade.responseToUserViewButtonAction(
                    dependency: dependency,
                    user: user,
                    buttonState: .follow
                )
            }
        }
    }
}
