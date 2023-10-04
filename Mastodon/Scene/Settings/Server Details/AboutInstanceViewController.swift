// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol AboutInstanceViewControllerDelegate: AnyObject {

}

class AboutInstanceViewController: UIViewController {
    weak var delegate: AboutInstanceViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

