// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonCore
import MastodonSDK
import MastodonLocalization

class SearchResultOverviewCoordinator: Coordinator {

    let overviewViewController: SearchResultsOverviewTableViewController
    let sceneCoordinator: SceneCoordinator
    let context: AppContext
    let authContext: AuthContext

    var activeTask: Task<Void, Never>?

    init(appContext: AppContext, authContext: AuthContext, sceneCoordinator: SceneCoordinator) {
        self.sceneCoordinator = sceneCoordinator
        self.context = appContext
        self.authContext = authContext

        overviewViewController = SearchResultsOverviewTableViewController(appContext: appContext, authContext: authContext, sceneCoordinator: sceneCoordinator)
    }

    func start() {
        overviewViewController.delegate = self
    }
}

extension SearchResultOverviewCoordinator: SearchResultsOverviewTableViewControllerDelegate {
    @MainActor
    func searchForPosts(_ viewController: SearchResultsOverviewTableViewController, withSearchText searchText: String) {
        let searchResultViewModel = SearchResultViewModel(context: context, authContext: authContext, searchScope: .posts, searchText: searchText)

        sceneCoordinator.present(scene: .searchResult(viewModel: searchResultViewModel), transition: .show)
    }

    func showPosts(_ viewController: SearchResultsOverviewTableViewController, tag: Mastodon.Entity.Tag) {
        Task {
            await DataSourceFacade.coordinateToHashtagScene(
                provider: viewController,
                tag: tag
            )

            await DataSourceFacade.responseToCreateSearchHistory(provider: viewController,
                                                                 item: .hashtag(tag: .entity(tag)))
        }
    }

    @MainActor
    func searchForPeople(_ viewController: SearchResultsOverviewTableViewController, withName searchText: String) {
        let searchResultViewModel = SearchResultViewModel(context: context, authContext: authContext, searchScope: .people, searchText: searchText)

        sceneCoordinator.present(scene: .searchResult(viewModel: searchResultViewModel), transition: .show)
    }

    func goTo(_ viewController: SearchResultsOverviewTableViewController, urlString: String) {

        let query = Mastodon.API.V2.Search.Query(
            q: urlString,
            type: .default,
            resolve: true
        )

        let authContext = self.authContext
        let managedObjectContext = context.managedObjectContext

        Task {
            let searchResult = try await context.apiService.search(
                query: query,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value

            if let account = searchResult.accounts.first {
                showProfile(viewController, for: account)
            } else if let status = searchResult.statuses.first {

                await DataSourceFacade.coordinateToStatusThreadScene(
                    provider: viewController,
                    target: .status,    // remove reblog wrapper
                    status: MastodonStatus.fromEntity(status)
                )
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

                await sceneCoordinator.present(scene: .safari(url: prefixedURL), transition: .safariPresent(animated: true))
            }
        }
    }

    func showProfile(_ viewController: SearchResultsOverviewTableViewController, for account: Mastodon.Entity.Account) {
        let managedObjectContext = context.managedObjectContext
        let domain = authContext.mastodonAuthenticationBox.domain

        Task {
            let user = try await managedObjectContext.perform {
                return Persistence.MastodonUser.fetch(in: managedObjectContext,
                                                      context: Persistence.MastodonUser.PersistContext(
                                                        domain: domain,
                                                        entity: account,
                                                        cache: nil,
                                                        networkDate: Date()
                                                      ))
            }

            if let user {
                await DataSourceFacade.coordinateToProfileScene(provider: viewController,
                                                                user: user.asRecord)

                await DataSourceFacade.responseToCreateSearchHistory(provider: viewController,
                                                                     item: .user(record: user.asRecord))
            }
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
            let searchResult = try await context.apiService.search(
                query: query,
                authenticationBox: authContext.mastodonAuthenticationBox
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
                    sceneCoordinator.present(scene: .alertController(alertController: alertController), transition: .alertController(animated: true))
                }
            }
        }
    }
}
