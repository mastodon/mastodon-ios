// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import AuthenticationServices

protocol SettingsCoordinatorDelegate: AnyObject {
    func logout(_ settingsCoordinator: SettingsCoordinator)
    func openGithubURL(_ settingsCoordinator: SettingsCoordinator)
    func openPrivacyURL(_ settingsCoordinator: SettingsCoordinator)
    func openProfileSettingsURL(_ settingsCoordinator: SettingsCoordinator)
}

class SettingsCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    let presentedOn: UIViewController

    weak var delegate: SettingsCoordinatorDelegate?

    private let settingsViewController: SettingsViewController

    init(presentedOn: UIViewController, accountName: String) {
        self.presentedOn = presentedOn
        navigationController = UINavigationController()

        settingsViewController = SettingsViewController(accountName: accountName)
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
            let aboutViewController = AboutViewController()
            aboutViewController.delegate = self

            navigationController.pushViewController(aboutViewController, animated: true)
        case .supportMastodon:
            break
            // present support-screen
        case .logout(_):
            delegate?.logout(self)
        }
    }
}

extension SettingsCoordinator: AboutViewControllerDelegate {
    func didSelect(_ viewController: AboutViewController, entry: AboutSettingsEntry) {
        switch entry {
        case .evenMoreSettings:
            delegate?.openProfileSettingsURL(self)
        case .contributeToMastodon:
            delegate?.openGithubURL(self)
        case .privacyPolicy:
            delegate?.openPrivacyURL(self)
        case .clearMediaCache(_):
            //TODO: appContext.purgeCache()
            //FIXME: maybe we should inject an AppContext/AuthContext here instead of delegating everything to SceneCoordinator?
            break
        }
    }
}

extension SettingsCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return navigationController.view.window!
    }
}
