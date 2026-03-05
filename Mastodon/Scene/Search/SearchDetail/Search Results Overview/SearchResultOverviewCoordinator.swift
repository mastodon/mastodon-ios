// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonCore
import MastodonSDK
import MastodonLocalization

protocol SearchResultOverviewCoordinatorDelegate: AnyObject {
    func newSearchHistoryItemAdded(_ coordinator: SearchResultOverviewCoordinator)
}

class SearchResultOverviewCoordinator: Coordinator {

    let overviewViewController: SearchResultsOverviewTableViewController
    let authenticationBox: MastodonAuthenticationBox

    weak var delegate: SearchResultOverviewCoordinatorDelegate?

    var activeTask: Task<Void, Never>?

    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox

        overviewViewController = SearchResultsOverviewTableViewController(authenticationBox: authenticationBox)
    }

    func start() {
        overviewViewController.delegate = self
    }
}

extension SearchResultOverviewCoordinator: SearchResultsOverviewTableViewControllerDelegate {
    @MainActor
    func searchForPosts(_ viewController: SearchResultsOverviewTableViewController, withSearchText searchText: String) {
        let searchResultViewModel = SearchResultViewModel(authenticationBox: authenticationBox, searchScope: .posts, searchText: searchText)

        viewController.sceneCoordinator?.present(scene: .searchResult(viewModel: searchResultViewModel), transition: .show)
    }

    func showPosts(_ viewController: SearchResultsOverviewTableViewController, tag: Mastodon.Entity.Tag) {
        Task {
            await viewController.sceneCoordinator?.present(scene: .hashtagTimeline(tag), transition: .show)

            await LegacyDataSourceFacade.responseToCreateSearchHistory(provider: viewController,
                                                                 item: .hashtag(tag: tag))

            delegate?.newSearchHistoryItemAdded(self)
        }
    }

    @MainActor
    func searchForPeople(_ viewController: SearchResultsOverviewTableViewController, withName searchText: String) {
        let searchResultViewModel = SearchResultViewModel(authenticationBox: authenticationBox, searchScope: .people, searchText: searchText)

        viewController.sceneCoordinator?.present(scene: .searchResult(viewModel: searchResultViewModel), transition: .show)
    }

    func goTo(_ viewController: SearchResultsOverviewTableViewController, urlString: String) {

        let query = Mastodon.API.V2.Search.Query(
            q: urlString,
            type: .default,
            resolve: true
        )

        let authenticationBox = self.authenticationBox

        Task {
            let searchResult = try await APIService.shared.search(
                query: query,
                authenticationBox: authenticationBox
            ).value

            if let account = searchResult.accounts.first {
                showProfile(viewController, for: account)
            } else if let status = searchResult.statuses.first {
                await viewController.sceneCoordinator?.present(scene: .thread(status.reblog ?? status, authenticatedUserDomain: authenticationBox.domain), transition: .show)
            } else if let url = URL(string: urlString) {
                let prefixedURL: URL?
                if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    if components.scheme == nil {
                        components.scheme = "https"
                    }
                    prefixedURL = components.url
                } else {
                    prefixedURL = url
                }

                guard let prefixedURL else { return }

                await viewController.sceneCoordinator?.present(scene: .safari(url: prefixedURL), transition: .safariPresent(animated: true))
            }
        }
    }

    func showProfile(_ viewController: SearchResultsOverviewTableViewController, for account: Mastodon.Entity.Account) {
        Task { @MainActor in
            guard let myAccount = authenticationBox.cachedAccount else { return }
            let profile: ProfileType = {
                if account.acctWithDomain == myAccount.acctWithDomain {
                    .me(account)
                } else {
                    .notMe(me: myAccount, displayAccount: account, relationship: nil)
                }
            }()
            viewController.sceneCoordinator?.present(scene: .profile(profile), from: viewController, transition: .show)

            await LegacyDataSourceFacade.responseToCreateSearchHistory(provider: viewController,
                                                                 item: .account(account: account, relationship: nil))

            delegate?.newSearchHistoryItemAdded(self)
        }
    }

    func searchForPerson(_ viewController: SearchResultsOverviewTableViewController, username: String, domain: String) {
        let acct = "\(username)@\(domain)"
        let query = Mastodon.API.V2.Search.Query(
            q: acct,
            type: .accounts,
            resolve: true
        )

        Task {
            let searchResult = try await APIService.shared.search(
                query: query,
                authenticationBox: authenticationBox
            ).value

            if let account = searchResult.accounts.first(where: { $0.acctWithDomainIfMissing(domain).lowercased() == acct.lowercased() }) {
                showProfile(viewController, for: account)
            } else {
                await MainActor.run {
                    let alertTitle = L10n.Scene.Search.Searching.NoUser.title
                    let alertMessage = L10n.Scene.Search.Searching.NoUser.message(username, domain)

                    let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default)
                    alertController.addAction(okAction)
                    viewController.sceneCoordinator?.present(scene: .alertController(alertController: alertController), transition: .alertController(animated: true))
                }
            }
        }
    }
}
