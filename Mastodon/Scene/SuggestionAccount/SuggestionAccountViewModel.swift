//
//  SuggestionAccountViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
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
//    let userFetchedResultsController: UserFetchedResultsController

    var viewWillAppear = PassthroughSubject<Void, Never>()

    // output
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<RecommendAccountSection, RecommendAccountItem>?
    
    @Published var records = [Mastodon.Entity.Account]()
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
//        self.userFetchedResultsController = UserFetchedResultsController(
//            managedObjectContext: context.managedObjectContext,
//            domain: nil,
//            additionalPredicate: nil
//        )
        super.init()
                
//        userFetchedResultsController.domain = authContext.mastodonAuthenticationBox.domain

        // fetch recommended users
        Task {
            var users: [Mastodon.Entity.Account] = []
            do {
                let response = try await context.apiService.suggestionAccountV2(
                    query: .init(limit: 5),
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
                users = response.value.map { $0.account }
            } catch let error as Mastodon.API.Error where error.httpResponseStatus == .notFound {
                let response = try await context.apiService.suggestionAccount(
                    query: nil,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
                users = response.value.map { $0 }
            } catch {
                
            }
            
            guard users.isNotEmpty else { return }
            records = users
        }
        
        // fetch relationship
        $records
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

    func setupDiffableDataSource(
        tableView: UITableView,
        suggestionAccountTableViewCellDelegate: SuggestionAccountTableViewCellDelegate
    ) {
        tableViewDiffableDataSource = RecommendAccountSection.tableViewDiffableDataSource(
            tableView: tableView,
            context: context,
            configuration: RecommendAccountSection.Configuration(
                authContext: authContext,
                suggestionAccountTableViewCellDelegate: suggestionAccountTableViewCellDelegate
            )
        )

        $records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let tableViewDiffableDataSource = self.tableViewDiffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, RecommendAccountItem>()
                snapshot.appendSections([.main])
                let items: [RecommendAccountItem] = records.map { RecommendAccountItem.account($0) }
                snapshot.appendItems(items, toSection: .main)

                tableViewDiffableDataSource.applySnapshotUsingReloadData(snapshot)
            }
            .store(in: &disposeBag)
    }

    func followAllSuggestedAccounts(_ dependency: NeedsDependency & AuthContextProvider, completion: (() -> Void)? = nil) {

        Task {
            await withTaskGroup(of: Void.self, body: { taskGroup in
                for user in records {
                    taskGroup.addTask {
                        try? await DataSourceFacade.responseToUserViewButtonAction(
                            dependency: dependency,
                            user: user,
                            buttonState: .follow
                        )
                    }
                }
            })

            delegate?.homeTimelineNeedRefresh.send()
            completion?()
        }
    }
}
