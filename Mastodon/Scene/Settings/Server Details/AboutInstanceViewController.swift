// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

protocol AboutInstanceViewControllerDelegate: AnyObject {

}

class AboutInstanceViewController: UIViewController {
    weak var delegate: AboutInstanceViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .green
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(with instance: Mastodon.Entity.V2.Instance) {
        //TODO: Implement
    }
}

