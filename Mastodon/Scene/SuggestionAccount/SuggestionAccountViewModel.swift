//
//  SuggestionAccountViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
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
    @Published var accounts: [Mastodon.Entity.V2.SuggestionAccount]
    var relationships: [Mastodon.Entity.Relationship]

    var viewWillAppear = PassthroughSubject<Void, Never>()

    // output
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<RecommendAccountSection, RecommendAccountItem>?
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext

        accounts = []
        relationships = []

        super.init()

        updateSuggestions()
    }


    func updateSuggestions() {
        Task {
            var suggestedAccounts: [Mastodon.Entity.V2.SuggestionAccount] = []
            do {
                let response = try await context.apiService.suggestionAccountV2(
                    query: .init(limit: 5),
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
                suggestedAccounts = response.value

                guard suggestedAccounts.isNotEmpty else { return }

                let accounts = suggestedAccounts.compactMap { $0.account }

                let relationships = try await context.apiService.relationship(
                    forAccounts: accounts,
                    authenticationBox: authContext.mastodonAuthenticationBox
                ).value

                self.relationships = relationships
                self.accounts = suggestedAccounts
            } catch {
                self.relationships = []
                self.accounts = []
            }
        }
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

        $accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] suggestedAccounts in
                guard let self, let tableViewDiffableDataSource = self.tableViewDiffableDataSource else { return }

                let accounts = suggestedAccounts.compactMap { $0.account }

                let accountsWithRelationship: [(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)] = accounts.compactMap { account in
                    guard let relationship = self.relationships.first(where: {$0.id == account.id }) else { return (account: account, relationship: nil)}

                    return (account: account, relationship: relationship)
                }

                var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, RecommendAccountItem>()
                snapshot.appendSections([.main])
                let items: [RecommendAccountItem] = accountsWithRelationship.map { RecommendAccountItem.account($0.account, relationship: $0.relationship) }
                snapshot.appendItems(items, toSection: .main)

                tableViewDiffableDataSource.applySnapshotUsingReloadData(snapshot)
            }
            .store(in: &disposeBag)
    }

    func followAllSuggestedAccounts(_ dependency: NeedsDependency & AuthContextProvider, presentedOn: UIViewController?, completion: (() -> Void)? = nil) {

        let tmpAccounts = accounts.compactMap { $0.account }

        Task {
            await dependency.coordinator.showLoading(on: presentedOn)
            await withTaskGroup(of: Void.self, body: { taskGroup in
                for account in tmpAccounts {
                    taskGroup.addTask {
                        try? await DataSourceFacade.responseToUserViewButtonAction(
                            dependency: dependency,
                            account: account,
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
