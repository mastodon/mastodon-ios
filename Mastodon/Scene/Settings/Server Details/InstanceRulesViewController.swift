// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

protocol InstanceRulesViewControllerDelegate: AnyObject {

}

class InstanceRulesViewController: UIViewController {
    weak var delegate: InstanceRulesViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .blue
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(with instance: Mastodon.Entity.V2.Instance) {
        //TODO: Implement
    }
}
