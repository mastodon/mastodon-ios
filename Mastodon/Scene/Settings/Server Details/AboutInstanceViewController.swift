// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

protocol AboutInstanceViewControllerDelegate: AnyObject {
    func showAdminAccount(_ viewController: AboutInstanceViewController, account: Mastodon.Entity.Account)
    func sendEmailToAdmin(_ viewController: AboutInstanceViewController, emailAddress: String)
}

class AboutInstanceViewController: UIViewController {
    
    weak var delegate: AboutInstanceViewControllerDelegate?
    var dataSource: UITableViewDiffableDataSource<AboutInstanceSection, AboutInstanceItem>?

    let tableView: UITableView
    var instance: Mastodon.Entity.V2.Instance?

    init() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ContactAdminTableViewCell.self, forCellReuseIdentifier: ContactAdminTableViewCell.reuseIdentifier)
        tableView.register(AdminTableViewCell.self, forCellReuseIdentifier: AdminTableViewCell.reuseIdentifier)
        super.init(nibName: nil, bundle: nil)

        let dataSource = UITableViewDiffableDataSource<AboutInstanceSection, AboutInstanceItem>(tableView: tableView) { tableView, indexPath, itemIdentifier in
            switch itemIdentifier {

                case .adminAccount(let account):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminTableViewCell.reuseIdentifier, for: indexPath) as? AdminTableViewCell else { fatalError("WTF?! Wrong cell.") }

                    cell.condensedUserView.configure(with: account, showFollowers: false)

                    return cell

                case .contactAdmin:
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactAdminTableViewCell.reuseIdentifier, for: indexPath) as? ContactAdminTableViewCell else { fatalError("WTF?! Wrong cell.") }

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
    }
        //TODO: Implement
    }
}

extension AboutInstanceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO: Implement

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
