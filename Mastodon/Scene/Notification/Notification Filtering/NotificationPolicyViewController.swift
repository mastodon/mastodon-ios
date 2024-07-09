// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization
import MastodonAsset
import MastodonCore

enum NotificationFilterSection: Hashable {
    case main
}

enum NotificationFilterItem: Hashable,  CaseIterable {
    case notFollowing
    case noFollower
    case newAccount
    case privateMentions

    var title: String {
        // TODO: Localization
        switch self {
        case .notFollowing:
            return "People you don't follow"
        case .noFollower:
            return "People not following you"
        case .newAccount:
            return "New accounts"
        case .privateMentions:
            return "Unsolicited private mentions"
        }
    }

    var subtitle: String {
        // TODO: Localization
        switch self {
        case .notFollowing:
            return "Until you manually approve them"
        case .noFollower:
            return "Including people who have been following you fewer than 3 days"
        case .newAccount:
            return "Created within the past 30 days"
        case .privateMentions:
            return "Filtered unless it’s in reply to your own mention or if you follow the sender"
        }
    }
}

struct NotificationFilterViewModel {
    var notFollowing: Bool
    var noFollower: Bool
    var newAccount: Bool
    var privateMentions: Bool

    let appContext: AppContext

    init(appContext: AppContext, notFollowing: Bool, noFollower: Bool, newAccount: Bool, privateMentions: Bool) {
        self.appContext = appContext
        self.notFollowing = notFollowing
        self.noFollower = noFollower
        self.newAccount = newAccount
        self.privateMentions = privateMentions
    }
}

class NotificationPolicyViewController: UIViewController {

    let tableView: UITableView
    var saveItem: UIBarButtonItem?
    var dataSource: UITableViewDiffableDataSource<NotificationFilterSection, NotificationFilterItem>?
    let items: [NotificationFilterItem]
    var viewModel: NotificationFilterViewModel

    init(viewModel: NotificationFilterViewModel) {
        self.viewModel = viewModel
        items = NotificationFilterItem.allCases

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationPolicyFilterTableViewCell.self, forCellReuseIdentifier: NotificationPolicyFilterTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        let dataSource = UITableViewDiffableDataSource<NotificationFilterSection, NotificationFilterItem>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self, let cell = tableView.dequeueReusableCell(withIdentifier: NotificationPolicyFilterTableViewCell.reuseIdentifier, for: indexPath) as? NotificationPolicyFilterTableViewCell else {
                fatalError("No NotificationPolicyFilterTableViewCell")
            }

            let item = items[indexPath.row]
            cell.configure(with: item, viewModel: self.viewModel)
            cell.delegate = self

            return cell
        }

        // TODO: Localization
        title = "Filter Notifications from"

        tableView.dataSource = dataSource
        tableView.delegate = self

        self.dataSource = dataSource
        view.addSubview(tableView)
        view.backgroundColor = .systemGroupedBackground

        saveItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.save, style: .done, target: self, action: #selector(NotificationPolicyViewController.save(_:)))
        navigationItem.rightBarButtonItem = saveItem
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .done, target: self, action: #selector(NotificationPolicyViewController.cancel(_:)))

        setupConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<NotificationFilterSection, NotificationFilterItem>()

        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Action

    @objc private func save(_ sender: UIBarButtonItem) {
        guard let authenticationBox = viewModel.appContext.authenticationService.mastodonAuthenticationBoxes.first else { return }

        navigationItem.leftBarButtonItem?.isEnabled = false

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem?.isEnabled = false

        activityIndicator.startAnimating()

        Task { [weak self] in
            guard let self else { return }

            do {
                let result = try await viewModel.appContext.apiService.updateNotificationPolicy(
                    authenticationBox: authenticationBox,
                    filterNotFollowing: viewModel.notFollowing,
                    filterNotFollowers: viewModel.noFollower,
                    filterNewAccounts: viewModel.newAccount,
                    filterPrivateMentions: viewModel.privateMentions
                )

                await MainActor.run {
                    self.dismiss(animated:true)
                }
            } catch {
                navigationItem.rightBarButtonItem = saveItem
                navigationItem.rightBarButtonItem?.isEnabled = true
                navigationItem.leftBarButtonItem?.isEnabled = true
            }
        }

    }

    @objc private func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

extension NotificationPolicyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let filterItem = items[indexPath.row]
        switch filterItem {
        case .notFollowing:
            viewModel.notFollowing.toggle()
        case .noFollower:
            viewModel.noFollower.toggle()
        case .newAccount:
            viewModel.newAccount.toggle()
        case .privateMentions:
            viewModel.privateMentions.toggle()
        }

        if let snapshot = dataSource?.snapshot() {
            dataSource?.applySnapshotUsingReloadData(snapshot)
        }
    }
}

extension NotificationPolicyViewController: NotificationPolicyFilterTableViewCellDelegate {
    func toggleValueChanged(_ tableViewCell: NotificationPolicyFilterTableViewCell, filterItem: NotificationFilterItem, newValue: Bool) {
        switch filterItem {
        case .notFollowing:
            viewModel.notFollowing = newValue
        case .noFollower:
            viewModel.noFollower = newValue
        case .newAccount:
            viewModel.newAccount = newValue
        case .privateMentions:
            viewModel.privateMentions = newValue
        }
    }
}
