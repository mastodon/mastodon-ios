// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import MastodonCore

@MainActor
protocol AboutInstanceViewControllerDelegate: AnyObject {
    func showAdminAccount(_ viewController: AboutInstanceViewController, account: Mastodon.Entity.Account)
    func sendEmailToAdmin(_ viewController: AboutInstanceViewController, emailAddress: String)
}

class AboutInstanceViewController: UIViewController, AuthContextProvider {

    var authenticationBox: MastodonAuthenticationBox

    weak var delegate: AboutInstanceViewControllerDelegate?
    var dataSource: AboutInstanceTableViewDataSource?

    let tableView: UITableView
    let headerView: AboutInstanceTableHeaderView
    let footerView: AboutInstanceTableFooterView

    var instance: Mastodon.Entity.V2.Instance?

    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ContactAdminTableViewCell.self, forCellReuseIdentifier: ContactAdminTableViewCell.reuseIdentifier)
        tableView.register(AdminTableViewCell.self, forCellReuseIdentifier: AdminTableViewCell.reuseIdentifier)

        headerView = AboutInstanceTableHeaderView()
        footerView = AboutInstanceTableFooterView()

        super.init(nibName: nil, bundle: nil)

        let dataSource = AboutInstanceTableViewDataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
            switch itemIdentifier {

                case .adminAccount(let account):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminTableViewCell.reuseIdentifier, for: indexPath) as? AdminTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }

                    cell.condensedUserView.configure(with: account, showFollowers: false)

                    return cell

                case .contactAdmin:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactAdminTableViewCell.reuseIdentifier, for: indexPath) as? ContactAdminTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }

                    cell.configure()

                    return cell
            }
        }

        tableView.delegate = self
        tableView.dataSource = dataSource

        self.dataSource = dataSource

        view.addSubview(tableView)

        setupConstraints()
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

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let tableHeaderView = tableView.tableHeaderView {
            let size = tableHeaderView.systemLayoutSizeFitting(.init(width: self.tableView.frame.width, height: 10_000))
            tableHeaderView.frame.size = size
            tableView.tableHeaderView = tableHeaderView
        }

        if let tableFooterView = tableView.tableFooterView {
            let size = tableFooterView.systemLayoutSizeFitting(.init(width: self.tableView.frame.width, height: 10_000))
            tableFooterView.frame.size = size
            tableView.tableFooterView = tableFooterView
        }

        super.viewWillLayoutSubviews()
    }

    func update(with instance: Mastodon.Entity.V2.Instance) {

        self.instance = instance
        var snapshot = NSDiffableDataSourceSnapshot<AboutInstanceSection, AboutInstanceItem>()

        snapshot.appendSections([.main])
        if let account = instance.contact?.account {
            snapshot.appendItems([.adminAccount(account)], toSection: .main)
        }

        if let email = instance.contact?.email {
            snapshot.appendItems([.contactAdmin(email)], toSection: .main)
        }

        dataSource?.apply(snapshot, animatingDifferences: false)

        guard let thumbnailUrlString = instance.thumbnail?.url, let thumbnailUrl = URL(string: thumbnailUrlString) else { return }

        DispatchQueue.main.async {
            self.headerView.updateImage(with: thumbnailUrl) { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }

                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    func updateFooter(with extendedDescription: Mastodon.Entity.ExtendedDescription) {
        DispatchQueue.main.async {
            self.footerView.update(with: extendedDescription)

            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}

extension AboutInstanceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let snapshot = dataSource?.snapshot() else {
            return tableView.deselectRow(at: indexPath, animated: true)
        }

        switch snapshot.itemIdentifiers(inSection: .main)[indexPath.row] {
            case .adminAccount(let account):
                delegate?.showAdminAccount(self, account: account)
            case .contactAdmin(let email):
                delegate?.sendEmailToAdmin(self, emailAddress: email)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
