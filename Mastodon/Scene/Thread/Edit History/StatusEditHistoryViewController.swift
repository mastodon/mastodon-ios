// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import CoreDataStack

class StatusEditHistoryViewController: UIViewController {

    private let tableView: UITableView

    var tableViewDataSource: UITableViewDiffableDataSource<Int, StatusEdit>?
    var viewModel: StatusEditHistoryViewModel

    init(viewModel: StatusEditHistoryViewModel) {

        self.viewModel = viewModel

        tableView = UITableView(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(StatusEditHistoryTableViewCell.self, forCellReuseIdentifier: StatusEditHistoryTableViewCell.identifier)

        let tableViewDataSource = UITableViewDiffableDataSource<Int, StatusEdit>(tableView: tableView) {tableView, indexPath, itemIdentifier in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: StatusEditHistoryTableViewCell.identifier, for: indexPath) as? StatusEditHistoryTableViewCell else {
                fatalError("Wrong cell")
            }

            let editEntry = viewModel.edits[indexPath.row]
            cell.configure(status: viewModel.status, statusEdit: editEntry)

            return cell
        }

        tableView.dataSource = tableViewDataSource
        self.tableViewDataSource = tableViewDataSource

        super.init(nibName: nil, bundle: nil)

        view.addSubview(tableView)

        view.backgroundColor = .systemBackground
        setupConstraints()

        title = "Edit History"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = tableView.pinTo(to: view)
        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<Int, StatusEdit>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.edits)

        tableViewDataSource?.apply(snapshot)
    }
}
