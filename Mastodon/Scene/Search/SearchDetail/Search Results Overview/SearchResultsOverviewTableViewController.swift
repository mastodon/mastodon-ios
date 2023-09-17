// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonCore
import MastodonSDK

protocol SearchResultsOverviewTableViewControllerDeleagte: AnyObject {
    func showPeople(_ viewController: UIViewController)
    func showProfile(_ viewController: UIViewController)
    func openLink(_ viewController: UIViewController)
}

// we could move lots of this stuff to a coordinator, it's too much for work a viewcontroller
class SearchResultsOverviewTableViewController: UIViewController, NeedsDependency, AuthContextProvider {
    // similar to the other search results view controller but without the whole statemachine bullshit
    // with scope all

    var context: AppContext!
    let authContext: AuthContext
    var coordinator: SceneCoordinator!

    private let tableView: UITableView
    var dataSource: UITableViewDiffableDataSource<SearchResultOverviewSection, SearchResultOverviewItem>?

    weak var delegate: SearchResultsOverviewTableViewControllerDeleagte?
    var activeTask: Task<Void, Never>?

    init(appContext: AppContext, authContext: AuthContext, coordinator: SceneCoordinator) {

        self.context = appContext
        self.authContext = authContext
        self.coordinator = coordinator

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(SearchResultDefaultSectionTableViewCell.self, forCellReuseIdentifier: SearchResultDefaultSectionTableViewCell.reuseIdentifier)
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: StatusTableViewCell.reuseIdentifier)
        tableView.register(HashtagTableViewCell.self, forCellReuseIdentifier: HashtagTableViewCell.reuseIdentifier)
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: UserTableViewCell.reuseIdentifier)

        let dataSource = UITableViewDiffableDataSource<SearchResultOverviewSection, SearchResultOverviewItem>(tableView: tableView) { tableView, indexPath, itemIdentifier in
            switch itemIdentifier {

                case .default(let item):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultDefaultSectionTableViewCell.reuseIdentifier, for: indexPath) as? SearchResultDefaultSectionTableViewCell else { fatalError() }

                    cell.configure(item: item)

                    return cell

                case .suggestion(let suggestion):

                    switch suggestion {

                        case .hashtag(let hashtag):


                            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultDefaultSectionTableViewCell.reuseIdentifier, for: indexPath) as? SearchResultDefaultSectionTableViewCell else { fatalError() }

                            cell.configure(item: .hashtag(tag: hashtag))
                            return cell

                            //
                        case .profile(let profile):
                            guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.reuseIdentifier, for: indexPath) as? UserTableViewCell else { fatalError() }

                            // how the fuck do I get a MastodonUser???
                            let managedObjectContext = appContext.managedObjectContext
                            Task {
                                do {

                                    try await managedObjectContext.perform {
                                        guard let user = Persistence.MastodonUser.fetch(in: managedObjectContext,
                                                                                  context: Persistence.MastodonUser.PersistContext(
                                                                                    domain: authContext.mastodonAuthenticationBox.domain,
                                                                                    entity: profile,
                                                                                    cache: nil,
                                                                                    networkDate: Date()
                                                                                  )) else { return }

                                        cell.configure(
                                            me: authContext.mastodonAuthenticationBox.authenticationRecord.object(in: managedObjectContext)?.user,
                                            tableView: tableView,
                                            viewModel: UserTableViewCell.ViewModel(
                                                user: user,
                                                followedUsers: authContext.mastodonAuthenticationBox.inMemoryCache.$followingUserIds.eraseToAnyPublisher(),
                                                blockedUsers: authContext.mastodonAuthenticationBox.inMemoryCache.$blockedUserIds.eraseToAnyPublisher(),
                                                followRequestedUsers: authContext.mastodonAuthenticationBox.inMemoryCache.$followRequestedUserIDs.eraseToAnyPublisher()),
                                            delegate: nil)
                                    }
                                }
                                catch {
                                    // do nothing
                                }
                            }

                            return cell
                    }
            }
        }

        super.init(nibName: nil, bundle: nil)
        tableView.dataSource = dataSource
        tableView.delegate = self
        self.dataSource = dataSource


        view.addSubview(tableView)
        tableView.pinToParent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<SearchResultOverviewSection, SearchResultOverviewItem>()
        snapshot.appendSections([.default, .suggestions])
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    func showStandardSearch(for searchText: String) {

        guard let dataSource else { return }

        var snapshot = dataSource.snapshot()
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .default))
        snapshot.appendItems([.default(.posts(searchText)),
                              .default(.people(searchText)),
                              .default(.profile(searchText, authContext.mastodonAuthenticationBox.domain))], toSection: .default)

        if URL(string: searchText) != nil {
            //TODO: Check if Mastodon-URL
            snapshot.appendItems([.default(.openLink(searchText))], toSection: .default)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func searchForSuggestions(for searchText: String) {

        activeTask?.cancel()

        guard let dataSource else { return }

        var snapshot = dataSource.snapshot()
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .suggestions))
        dataSource.apply(snapshot, animatingDifferences: false)

        guard searchText.isNotEmpty else { return }

        let query = Mastodon.API.V2.Search.Query(
            q: searchText,
            type: .default,
            resolve: true
        )

        let searchTask = Task {
            do {
                let searchResult = try await context.apiService.search(
                    query: query,
                    authenticationBox: authContext.mastodonAuthenticationBox
                ).value
                
                let firstThreeHashtags = searchResult.hashtags.prefix(3)
                let firstThreeUsers = searchResult.accounts.prefix(3)

                var snapshot = dataSource.snapshot()

                if firstThreeHashtags.isNotEmpty {
                    snapshot.appendItems(firstThreeHashtags.map { .suggestion(.hashtag(tag: $0)) }, toSection: .suggestions )
                }

                if firstThreeUsers.isNotEmpty {
                    snapshot.appendItems(firstThreeUsers.map { .suggestion(.profile(user: $0)) }, toSection: .suggestions )
                }

                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    dataSource.apply(snapshot, animatingDifferences: false)
                }
                
            } catch {
                // do nothing
                print(error.localizedDescription)
            }
        }

        activeTask = searchTask
    }

    func showPosts(tag: Mastodon.Entity.Tag) {
        Task {
            await DataSourceFacade.coordinateToHashtagScene(
                provider: self,
                tag: tag
            )
        }
    }

    func showProfile(for account: Mastodon.Entity.Account) {
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
                await DataSourceFacade.coordinateToProfileScene(provider:self,
                                                                user: user.asRecord)
            }
        }
    }
}

//MARK: UITableViewDelegate
extension SearchResultsOverviewTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        //TODO: Implement properly!
        guard let snapshot = dataSource?.snapshot() else { return }
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]

        switch item {
            case .default(let defaultSectionEntry):
                switch defaultSectionEntry {
                    case .posts(let hashtag):
                        //FIXME: Show statuses instead of tag-content. Reuse SearchResultsViewController with statuses here?
                        showPosts(tag: Mastodon.Entity.Tag(name: hashtag, url: authContext.mastodonAuthenticationBox.domain))
                    case .people(let string):
                        //FIXME: Invoke SearchResultsViewController with people-scope here
                        delegate?.showPeople(self)
                    case .profile(let profile, let instanceName):
                        delegate?.showProfile(self)
                    case .openLink(let string):
                        delegate?.openLink(self)
                }
            case .suggestion(let suggestionSectionEntry):
                switch suggestionSectionEntry {

                    case .hashtag(let tag):
                        showPosts(tag: tag)
                    case .profile(let account):
                        showProfile(for: account)
                }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
