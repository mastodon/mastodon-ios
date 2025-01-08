// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization
import MastodonAsset
import MastodonCore
import MastodonSDK

enum NotificationFilterSection: Hashable {
    case main
}

enum NotificationFilterItem: Hashable,  CaseIterable {
    case notFollowing
    case noFollower
    case newAccount
    case privateMentions

    var title: String {
        switch self {
        case .notFollowing:
            return L10n.Scene.Notification.Policy.NotFollowing.title
        case .noFollower:
            return L10n.Scene.Notification.Policy.NoFollower.title
        case .newAccount:
            return L10n.Scene.Notification.Policy.NewAccount.title
        case .privateMentions:
            return L10n.Scene.Notification.Policy.PrivateMentions.title
        }
    }

    var subtitle: String {
        switch self {
        case .notFollowing:
            return L10n.Scene.Notification.Policy.NotFollowing.subtitle
        case .noFollower:
            return L10n.Scene.Notification.Policy.NoFollower.subtitle
        case .newAccount:
            return L10n.Scene.Notification.Policy.NewAccount.subtitle
        case .privateMentions:
            return L10n.Scene.Notification.Policy.PrivateMentions.subtitle
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

protocol NotificationPolicyViewControllerDelegate: AnyObject {
    func policyUpdated(_ viewController: NotificationPolicyViewController, newPolicy: Mastodon.Entity.NotificationPolicy)
}

class NotificationPolicyViewController: UIViewController {

    let tableView: UITableView
    let headerBar: NotificationPolicyHeaderView
    var saveItem: UIBarButtonItem?
    var dataSource: UITableViewDiffableDataSource<NotificationFilterSection, NotificationFilterItem>?
    let items: [NotificationFilterItem]
    var viewModel: NotificationFilterViewModel
    weak var delegate: NotificationPolicyViewControllerDelegate?

    init(viewModel: NotificationFilterViewModel) {
        self.viewModel = viewModel
        items = NotificationFilterItem.allCases

        headerBar = NotificationPolicyHeaderView()
        headerBar.translatesAutoresizingMaskIntoConstraints = false

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationPolicyFilterTableViewCell.self, forCellReuseIdentifier: NotificationPolicyFilterTableViewCell.reuseIdentifier)
        tableView.contentInset.top = -20

        super.init(nibName: nil, bundle: nil)

        let dataSource = UITableViewDiffableDataSource<NotificationFilterSection, NotificationFilterItem>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self, let cell = tableView.dequeueReusableCell(withIdentifier: NotificationPolicyFilterTableViewCell.reuseIdentifier, for: indexPath) as? NotificationPolicyFilterTableViewCell else {
                assertionFailure("unexpected cell dequeued")
                return nil
            }

            let item = items[indexPath.row]
            cell.configure(with: item, viewModel: self.viewModel)
            cell.delegate = self

            return cell
        }

        tableView.dataSource = dataSource
        tableView.delegate = self

        self.dataSource = dataSource
        view.addSubview(headerBar)
        view.addSubview(tableView)
        view.backgroundColor = .systemGroupedBackground
        headerBar.closeButton.addTarget(self, action: #selector(NotificationPolicyViewController.save(_:)), for: .touchUpInside)

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
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Action

    @objc private func save(_ sender: UIButton) {
        guard let authenticationBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }

        Task { [weak self] in
            guard let self else { return }

            do {
                let updatedPolicy = try await APIService.shared.updateNotificationPolicy(
                    authenticationBox: authenticationBox,
                    filterNotFollowing: viewModel.notFollowing,
                    filterNotFollowers: viewModel.noFollower,
                    filterNewAccounts: viewModel.newAccount,
                    filterPrivateMentions: viewModel.privateMentions
                ).value

                delegate?.policyUpdated(self, newPolicy: updatedPolicy)

                NotificationCenter.default.post(name: .notificationFilteringChanged, object: nil)

            } catch {}
        }

        dismiss(animated:true)
    }

    @objc private func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

//MARK: - UITableViewDelegate

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
