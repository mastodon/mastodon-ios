// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol SettingsCoordinatorDelegate: AnyObject {
    func logout(_ settingsCoordinator: SettingsCoordinator)
}

class SettingsCoordinator: Coordinator {

    let navigationController: UINavigationController
    let presentedOn: UIViewController

    weak var delegate: SettingsCoordinatorDelegate?

    private let settingsViewController: SettingsViewController

    init(presentedOn: UIViewController) {
        self.presentedOn = presentedOn
        navigationController = UINavigationController()

        settingsViewController = SettingsViewController(accountName: "born2jort")
    }

    func start() {
        settingsViewController.delegate = self

        navigationController.pushViewController(settingsViewController, animated: false)
        presentedOn.present(navigationController, animated: true)
    }
}

extension SettingsCoordinator: SettingsViewControllerDelegate {
    func done(_ viewController: UIViewController) {
        viewController.dismiss(animated: true)
    }

    func didSelect(_ viewController: UIViewController, entry: SettingsEntry) {
        switch entry {
        case .general:
            break
            // show general
        case .notifications:
            break
            // show notifications
        case .aboutMastodon:
            break
            // show about
        case .supportMastodon:
            break
            // present support-screen
        case .logout(_):
            delegate?.logout(self)
        }
    }

}
