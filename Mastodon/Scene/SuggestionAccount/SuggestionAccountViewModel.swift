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
    let authenticationBox: MastodonAuthenticationBox
    @Published var accounts: [Mastodon.Entity.V2.SuggestionAccount]
    var relationships: [String: Mastodon.Entity.Relationship]

    var viewWillAppear = PassthroughSubject<Void, Never>()

    // output
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<RecommendAccountSection, RecommendAccountItem>?
    
    init(
        authenticationBox: MastodonAuthenticationBox
    ) {
        self.authenticationBox = authenticationBox

        accounts = []
        relationships = [:]

        super.init()

        updateSuggestions()
    }


    func updateSuggestions() {
        Task {
            var suggestedAccounts: [Mastodon.Entity.V2.SuggestionAccount] = []
            do {
                let response = try await APIService.shared.suggestionAccountV2(
                    query: .init(limit: 5),
                    authenticationBox: authenticationBox
                )
                suggestedAccounts = response.value

                guard suggestedAccounts.isNotEmpty else { return }

                let accounts = suggestedAccounts.compactMap { $0.account }

                let relationships = try await APIService.shared.relationship(
                    forAccounts: accounts,
                    authenticationBox: authenticationBox
                )

                self.relationships = relationships
                self.accounts = suggestedAccounts
            } catch {
                self.relationships = [:]
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
            configuration: RecommendAccountSection.Configuration(
                authenticationBox: authenticationBox,
                suggestionAccountTableViewCellDelegate: suggestionAccountTableViewCellDelegate
            )
        )

        $accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] suggestedAccounts in
                guard let self, let tableViewDiffableDataSource = self.tableViewDiffableDataSource else { return }

                let accounts = suggestedAccounts.compactMap { $0.account }

                let accountsWithRelationship: [(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)] = accounts.compactMap { account in
                    guard let relationship = self.relationships[account.id] else { return (account: account, relationship: nil)}

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

    func followAllSuggestedAccounts(_ dependency: UIViewController & AuthContextProvider, presentedOn: UIViewController?, completion: (() -> Void)? = nil) {

        let tmpAccounts = accounts.compactMap { $0.account }

        Task {
            await dependency.sceneCoordinator?.showLoading(on: presentedOn)
            await withTaskGroup(of: Void.self, body: { taskGroup in
                for account in tmpAccounts {
                    taskGroup.addTask {
                        _ = try? await LegacyDataSourceFacade.responseToUserViewButtonAction(
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
