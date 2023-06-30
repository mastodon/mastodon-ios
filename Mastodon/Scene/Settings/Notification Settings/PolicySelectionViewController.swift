// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol PolicySelectionViewControllerDelegate: AnyObject {
    
}

class PolicySelectionViewController: UIViewController {

    weak var delegate: PolicySelectionViewControllerDelegate?

    //TODO: TableView with SubscriptionAlerts/NotificationAlert
    init(viewModel: NotificationSettingsViewModel) {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .systemGroupedBackground
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
