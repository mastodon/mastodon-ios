// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

class SettingsCoordinator: Coordinator {

    let navigationController: UINavigationController
    let presentedOn: UIViewController

    private let generalSettingsViewController: GeneralSettingsViewController

    init(presentedOn: UIViewController) {
        self.presentedOn = presentedOn
        navigationController = UINavigationController()

        generalSettingsViewController = GeneralSettingsViewController()
    }

    func start() {
        generalSettingsViewController.delegate = self

        navigationController.pushViewController(generalSettingsViewController, animated: false)
        presentedOn.present(navigationController, animated: true)
    }
}

extension SettingsCoordinator: GeneralSettingsViewControllerDelegate {

}
