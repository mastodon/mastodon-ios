// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

class StatusEditHistoryViewController: UIViewController {
    init(viewModel: StatusEditHistoryViewModel) {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .systemBackground
        //TODO: Add Localization
        title = "Edit History"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
