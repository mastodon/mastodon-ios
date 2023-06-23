// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol GeneralSettingsViewControllerDelegate: AnyObject {

}

class GeneralSettingsViewController: UIViewController {

    weak var delegate: GeneralSettingsViewControllerDelegate?
    let tableView: UITableView

    init() {

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        //TODO: Delegate
        //TODO: DiffableDataSource

        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .systemBackground

        
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
