// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit

struct NotificationRequestsViewModel {
    
}

class NotificationRequestsTableViewController: UIViewController {
    let tableView: UITableView

    init(viewModel: NotificationRequestsViewModel) {
        //TODO: Cell, DataSource, Delegate....
        tableView = UITableView(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground

        super.init(nibName: nil, bundle: nil)

        view.addSubview(tableView)
        tableView.pinToParent()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
