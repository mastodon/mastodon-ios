// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol ServerDetailsViewControllerDelegate: AnyObject {

}

class ServerDetailsViewController: UIViewController {
    weak var delegate: ServerDetailsViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .systemGroupedBackground
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

