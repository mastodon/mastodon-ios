// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import AuthenticationServices
import MastodonCore
import CoreDataStack

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

    let setting: Setting

    init(presentedOn: UIViewController, accountName: String, setting: Setting) {
        self.presentedOn = presentedOn
        navigationController = UINavigationController()
        self.setting = setting

        settingsViewController = SettingsViewController(accountName: accountName)
    }

    func start() {
        settingsViewController.delegate = self

        navigationController.pushViewController(settingsViewController, animated: false)
        presentedOn.present(navigationController, animated: true)
    }
}

//MARK: - SettingsViewControllerDelegate
extension SettingsCoordinator: SettingsViewControllerDelegate {
    func done(_ viewController: UIViewController) {
        viewController.dismiss(animated: true)
    }

    func didSelect(_ viewController: UIViewController, entry: SettingsEntry) {
        switch entry {
        case .general:
            let generalSettingsViewController = GeneralSettingsViewController(setting: setting)
            generalSettingsViewController.delegate = self

            navigationController.pushViewController(generalSettingsViewController, animated: true)
        case .notifications:
            let notificationViewController = NotificationSettingsViewController()
            notificationViewController.delegate = self

            navigationController.pushViewController(notificationViewController, animated: true)
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

//MARK: - AboutViewControllerDelegate
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
            //FIXME: maybe we should inject an AppContext/AuthContext here instead of delegating everything to SceneCoordinator?
            AppContext.shared.purgeCache()
            viewController.update(with:
                                    [AboutSettingsSection(entries: [
                                        .evenMoreSettings,
                                        .contributeToMastodon,
                                        .privacyPolicy
                                    ]),
                                     AboutSettingsSection(entries: [
                                        .clearMediaCache(AppContext.shared.currentDiskUsage())
                                     ])]
            )
        }
    }
}

//MARK: - ASWebAuthenticationPresentationContextProviding
extension SettingsCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return navigationController.view.window!
    }
}

//MARK: - GeneralSettingsViewControllerDelegate
extension SettingsCoordinator: GeneralSettingsViewControllerDelegate {
    func save(_ viewController: UIViewController, setting: Setting, viewModel: GeneralSettingsViewModel) {
        UserDefaults.shared.customUserInterfaceStyle = viewModel.selectedAppearence.interfaceStyle
        setting.update(preferredStaticEmoji: viewModel.playAnimations == false)
        setting.update(preferredStaticAvatar: viewModel.playAnimations == false)
        setting.update(preferredUsingDefaultBrowser: viewModel.selectedOpenLinks == .browser)
    }
}

//MARK: - NotificationSettingsViewControllerDelegate
extension SettingsCoordinator: NotificationSettingsViewControllerDelegate {
    func showPolicyList(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel) {
        let policyListViewController = PolicySelectionViewController(viewModel: viewModel)
        policyListViewController.delegate = self

        navigationController.pushViewController(policyListViewController, animated: true)
    }
}

//MARK: - PolicySelectionViewControllerDelegate
extension SettingsCoordinator: PolicySelectionViewControllerDelegate {
    
}
