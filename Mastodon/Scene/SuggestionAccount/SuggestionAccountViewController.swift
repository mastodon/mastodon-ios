//
//  SuggestionAccountViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import OSLog
import UIKit

class SuggestionAccountViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()

    var viewModel: SuggestionAccountViewModel!

    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(SuggestionAccountTableViewCell.self, forCellReuseIdentifier: String(describing: SuggestionAccountTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    lazy var tableHeader: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        view.frame = CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 156))
        return view
    }()

    let followExplainLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Scene.SuggestionAccount.followExplain
        label.textColor = Asset.Colors.Label.primary.color
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.numberOfLines = 0
        return label
    }()

    let avatarStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 15
        return stackView
    }()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", (#file as NSString).lastPathComponent, #line, #function)
    }
}

extension SuggestionAccountViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.Background.systemBackground.color
        title = L10n.Scene.SuggestionAccount.title
        navigationItem.rightBarButtonItem
            = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                              target: self,
                              action: #selector(SuggestionAccountViewController.doneButtonDidClick(_:)))

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        viewModel.diffableDataSource = RecommendAccountSection.tableViewDiffableDataSource(
            for: tableView,
            managedObjectContext: context.managedObjectContext,
            viewModel: viewModel,
            delegate: self
        )

        viewModel.accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                guard let self = self else { return }
                self.setupHeader(accounts: accounts)
            }
            .store(in: &disposeBag)
    }

    func setupHeader(accounts: [NSManagedObjectID]) {
        if accounts.isEmpty {
            return
        }
        followExplainLabel.translatesAutoresizingMaskIntoConstraints = false
        tableHeader.addSubview(followExplainLabel)
        NSLayoutConstraint.activate([
            followExplainLabel.topAnchor.constraint(equalTo: tableHeader.topAnchor, constant: 20),
            followExplainLabel.leadingAnchor.constraint(equalTo: tableHeader.leadingAnchor, constant: 20),
            tableHeader.trailingAnchor.constraint(equalTo: followExplainLabel.trailingAnchor, constant: 20),
        ])

        avatarStackView.translatesAutoresizingMaskIntoConstraints = false
        tableHeader.addSubview(avatarStackView)
        NSLayoutConstraint.activate([
            avatarStackView.topAnchor.constraint(equalTo: followExplainLabel.topAnchor, constant: 20),
            avatarStackView.leadingAnchor.constraint(equalTo: tableHeader.leadingAnchor, constant: 20),
            avatarStackView.trailingAnchor.constraint(equalTo: tableHeader.trailingAnchor),
            avatarStackView.bottomAnchor.constraint(equalTo: tableHeader.bottomAnchor),
        ])
        let avatarImageViewHeight: Double = 56
        let avatarImageViewCount = Int(floor((Double(tableView.frame.width) - 20) / (avatarImageViewHeight + 15)))
        let count = min(avatarImageViewCount, accounts.count)
        for i in 0 ..< count {
            let account = context.managedObjectContext.object(with: accounts[i]) as! MastodonUser
            let imageView = UIImageView()
            imageView.layer.cornerRadius = 6
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: CGFloat(avatarImageViewHeight)),
                imageView.heightAnchor.constraint(equalToConstant: CGFloat(avatarImageViewHeight)),
            ])
            if let url = account.avatarImageURL() {
                imageView.af.setImage(
                    withURL: url,
                    placeholderImage: UIImage.placeholder(color: .systemFill),
                    imageTransition: .crossDissolve(0.2)
                )
            }
            avatarStackView.addArrangedSubview(imageView)
        }

        tableView.tableHeaderView = tableHeader
    }
}

extension SuggestionAccountViewController: SuggestionAccountTableViewCellDelegate {
    func accountButtonPressed(objectID: NSManagedObjectID, sender: UIButton) {
        let selected = !sender.isSelected
        sender.isSelected = !sender.isSelected
        if selected {
            viewModel.selectedAccounts.append(objectID)
        } else {
            viewModel.selectedAccounts.removeAll { $0 == objectID }
        }
    }
}

extension SuggestionAccountViewController {
    @objc func doneButtonDidClick(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        viewModel.followAction()
    }
}
