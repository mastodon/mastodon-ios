// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonCore
import MastodonSDK
import MastodonLocalization
import MastodonUI

protocol SearchResultsOverviewTableViewControllerDelegate: AnyObject {
    func goTo(_ viewController: SearchResultsOverviewTableViewController, urlString: String)
    func showPosts(_ viewController: SearchResultsOverviewTableViewController, tag: Mastodon.Entity.Tag)
    func searchForPosts(_ viewController: SearchResultsOverviewTableViewController, withSearchText searchText: String)
    func searchForPeople(_ viewController: SearchResultsOverviewTableViewController, withName searchText: String)
    func showProfile(_ viewController: SearchResultsOverviewTableViewController, for account: Mastodon.Entity.Account)
    func searchForPerson(_ viewController: SearchResultsOverviewTableViewController, username: String, domain: String)
}

class SearchResultsOverviewTableViewController: UIViewController, AuthContextProvider {
    let authenticationBox: MastodonAuthenticationBox

    private let tableView: UITableView
    var dataSource: UITableViewDiffableDataSource<SearchResultOverviewSection, SearchResultOverviewItem>?

    weak var delegate: SearchResultsOverviewTableViewControllerDelegate?

    var activeTask: Task<Void, Never>?

    init(authenticationBox: MastodonAuthenticationBox) {

        self.authenticationBox = authenticationBox

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorInset.left = 62
        tableView.register(SearchResultDefaultSectionTableViewCell.self, forCellReuseIdentifier: SearchResultDefaultSectionTableViewCell.reuseIdentifier)
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: StatusTableViewCell.reuseIdentifier)
        tableView.register(HashtagTableViewCell.self, forCellReuseIdentifier: HashtagTableViewCell.reuseIdentifier)
        tableView.register(SearchResultsProfileTableViewCell.self, forCellReuseIdentifier: SearchResultsProfileTableViewCell.reuseIdentifier)


        super.init(nibName: nil, bundle: nil)

        let dataSource = UITableViewDiffableDataSource<SearchResultOverviewSection, SearchResultOverviewItem>(tableView: tableView) { tableView, indexPath, itemIdentifier in

            switch itemIdentifier {
                case .default(let item):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultDefaultSectionTableViewCell.reuseIdentifier, for: indexPath) as? SearchResultDefaultSectionTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }

                    cell.configure(item: item)

                    return cell

                case .suggestion(let suggestion):
                    switch suggestion {
                        case .hashtag(let hashtag):
                            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultDefaultSectionTableViewCell.reuseIdentifier, for: indexPath) as? SearchResultDefaultSectionTableViewCell else {
                                assertionFailure("unexpected cell dequeued")
                                return nil
                            }

                            cell.configure(item: .hashtag(tag: hashtag))
                            return cell

                        case .profile(let profile):
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultsProfileTableViewCell.reuseIdentifier, for: indexPath) as? SearchResultsProfileTableViewCell else {
                            assertionFailure("unexpected cell dequeued")
                            return nil
                        }

                            cell.condensedUserView.configure(with: profile)

                            return cell
                    }
            }
        }

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

        if searchText.lowercased().starts(with: "https://") && (searchText.contains(" ") == false) {
            if URL(string: searchText)?.isValidURL() ?? false {
                snapshot.appendItems([.default(.openLink(searchText))], toSection: .default)
            }
        }

        if searchText.starts(with: "#") && searchText.length > 1 {
            snapshot.appendItems([.default(.showHashtag(hashtag: searchText.replacingOccurrences(of: "#", with: "")))],
                                 toSection: .default)
        } else if searchText.length > 1, let hashtagRegex = try? NSRegularExpression(pattern: MastodonRegex.Search.hashtag, options: .caseInsensitive), hashtagRegex.firstMatch(in: searchText, range: NSRange(location: 0, length: searchText.length-1)) != nil {
            snapshot.appendItems([.default(.showHashtag(hashtag: searchText.replacingOccurrences(of: "#", with: "")))],
                                 toSection: .default)
        }

        if searchText.length > 1,
            let usernameRegex = try? NSRegularExpression(pattern: MastodonRegex.Search.username, options: .caseInsensitive),
           usernameRegex.firstMatch(in: searchText, range: NSRange(location: 0, length: searchText.length-1)) != nil {
            let components = searchText.split(separator: "@")
            if components.count == 2 {
                let username = String(components[0]).replacingOccurrences(of: "@", with: "")

                let domain = String(components[1])
                if domain.split(separator: ".").count >= 2 {
                    snapshot.appendItems([.default(.showProfile(username: username, domain: domain))], toSection: .default)
                } else {
                    snapshot.appendItems([.default(.showProfile(username: username, domain: authenticationBox.domain))], toSection: .default)
                }
            } else {
                snapshot.appendItems([.default(.showProfile(username: searchText, domain: authenticationBox.domain))], toSection: .default)
            }
        }

        snapshot.appendItems([.default(.posts(matching: searchText)),
                              .default(.people(matching: searchText))], toSection: .default)

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
                let searchResult = try await APIService.shared.search(
                    query: query,
                    authenticationBox: authenticationBox
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
}

//MARK: UITableViewDelegate
extension SearchResultsOverviewTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let snapshot = dataSource?.snapshot() else { return }
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]

        switch item {
            case .default(let defaultSectionEntry):
                switch defaultSectionEntry {
                    case .posts(let searchText):
                        delegate?.searchForPosts(self, withSearchText: searchText)
                    case .people(let searchText):
                        delegate?.searchForPeople(self, withName: searchText)
                    case .showProfile(let username, let domain):
                        delegate?.searchForPerson(self, username: username, domain: domain)
                    case .openLink(let urlString):
                        delegate?.goTo(self, urlString: urlString)
                    case .showHashtag(let hashtagText):
                        let tag = Mastodon.Entity.Tag(name: hashtagText, url: "")
                        delegate?.showPosts(self, tag: tag)
                }
            case .suggestion(let suggestionSectionEntry):
                switch suggestionSectionEntry {

                    case .hashtag(let tag):
                        delegate?.showPosts(self, tag: tag)
                    case .profile(let account):
                        delegate?.showProfile(self, for: account)
                }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SearchResultsOverviewTableViewController: UserTableViewCellDelegate {}
