// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import CoreDataStack
import MastodonCore
import MastodonLocalization
import MastodonUI

class StatusEditHistoryViewController: UIViewController {

    private let tableView: UITableView

    var tableViewDataSource: UITableViewDiffableDataSource<Int, Mastodon.Entity.StatusEdit>?
    var viewModel: StatusEditHistoryViewModel
    private let dateFormatter: DateFormatter

    init(viewModel: StatusEditHistoryViewModel) {

        self.viewModel = viewModel
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        tableView = UITableView(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.register(StatusEditHistoryTableViewCell.self, forCellReuseIdentifier: StatusEditHistoryTableViewCell.identifier)

        super.init(nibName: nil, bundle: nil)

        let tableViewDataSource = UITableViewDiffableDataSource<Int, Mastodon.Entity.StatusEdit>(tableView: tableView) {tableView, indexPath, itemIdentifier in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: StatusEditHistoryTableViewCell.identifier, for: indexPath) as? StatusEditHistoryTableViewCell else {
                assertionFailure("unexpected cell dequeued")
                return nil
            }

            let statusEdit = viewModel.edits[indexPath.row]
            let dateText: String

            if statusEdit == viewModel.edits.last {
                dateText = L10n.Common.Controls.Status.EditHistory.originalPost(self.dateFormatter.string(from: statusEdit.createdAt))
            } else {
                dateText = self.dateFormatter.string(from: statusEdit.createdAt)
            }

            viewModel.prepareCell(cell, in: tableView)
            let contentWarning = ContentWarning(statusEdit: statusEdit)
            let contentDisplayModel = StatusView.ContentConcealViewModel(status: viewModel.status, filterBox: nil, filterContext: nil)
            let displayMode = contentDisplayModel.byShowingAll().effectiveDisplayMode
            cell.configure(status: viewModel.status, statusEdit: statusEdit, dateText: dateText, contentDisplayMode: displayMode)

            return cell
        }

        tableView.dataSource = tableViewDataSource
        tableView.backgroundColor = .secondarySystemBackground
        self.tableViewDataSource = tableViewDataSource


        view.addSubview(tableView)

        view.backgroundColor = .secondarySystemBackground
        setupConstraints()

        title = L10n.Common.Controls.Status.EditHistory.title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = tableView.pinTo(to: view)
        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<Int, Mastodon.Entity.StatusEdit>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.edits)

        tableViewDataSource?.apply(snapshot)
    }
}
