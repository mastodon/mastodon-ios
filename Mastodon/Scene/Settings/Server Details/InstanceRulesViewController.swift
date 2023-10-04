// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol InstanceRulesViewControllerDelegate: AnyObject {

}

class InstanceRulesViewController: UIViewController {
    weak var delegate: InstanceRulesViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
