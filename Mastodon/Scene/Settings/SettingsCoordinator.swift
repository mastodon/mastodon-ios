// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import AuthenticationServices
import MastodonCore
import CoreDataStack
import MastodonSDK
import Combine

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
    let appContext: AppContext
    let authContext: AuthContext
    var disposeBag = Set<AnyCancellable>()

    init(presentedOn: UIViewController, accountName: String, setting: Setting, appContext: AppContext, authContext: AuthContext) {
        self.presentedOn = presentedOn
        navigationController = UINavigationController()
        self.setting = setting
        self.appContext = appContext
        self.authContext = authContext

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

                let currentSetting = appContext.settingService.currentSetting.value
                let notificationsEnabled = appContext.notificationService.isNotificationPermissionGranted.value
                let notificationViewController = NotificationSettingsViewController(currentSetting: currentSetting, notificationsEnabled: notificationsEnabled)
                notificationViewController.delegate = self

                self.navigationController.pushViewController(notificationViewController, animated: true)

            case .aboutMastodon:
                let aboutViewController = AboutViewController()
                aboutViewController.delegate = self

                navigationController.pushViewController(aboutViewController, animated: true)
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
        UserDefaults.shared.preferredStaticEmoji = viewModel.playAnimations == false
        UserDefaults.shared.preferredStaticAvatar = viewModel.playAnimations == false
        UserDefaults.shared.preferredUsingDefaultBrowser = viewModel.selectedOpenLinks == .browser
    }
}

//MARK: - NotificationSettingsViewControllerDelegate
extension SettingsCoordinator: NotificationSettingsViewControllerDelegate {
    func showPolicyList(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel) {
        let policyListViewController = PolicySelectionViewController(viewModel: viewModel)
        policyListViewController.delegate = self

        navigationController.pushViewController(policyListViewController, animated: true)
    }

    func viewWillDisappear(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel) {

        guard viewModel.updated else { return }

        let authenticationBox = authContext.mastodonAuthenticationBox
        guard let subscription = setting.activeSubscription,
              setting.domain == authenticationBox.domain,
              setting.userID == authenticationBox.userID,
              let legacyViewModel = appContext.notificationService.dequeueNotificationViewModel(mastodonAuthenticationBox: authenticationBox), let deviceToken = appContext.notificationService.deviceToken.value else { return }

        let queryData = Mastodon.API.Subscriptions.QueryData(
            policy: viewModel.selectedPolicy.subscriptionPolicy,
            alerts: Mastodon.API.Subscriptions.QueryData.Alerts(
                favourite: viewModel.notifyFavorites,
                follow: viewModel.notifyNewFollowers,
                reblog: viewModel.notifyBoosts,
                mention: viewModel.notifyMentions,
                poll: subscription.alert.poll
            )
        )
        let query = legacyViewModel.createSubscribeQuery(
            deviceToken: deviceToken,
            queryData: queryData,
            mastodonAuthenticationBox: authenticationBox
        )

        appContext.apiService.createSubscription(
            subscriptionObjectID: subscription.objectID,
            query: query,
            mastodonAuthenticationBox: authenticationBox
        ).sink(receiveCompletion: { completion in
            print(completion)
        }, receiveValue: { output in
            print(output)
        })
        .store(in: &disposeBag)
    }
    
    func showNotificationSettings(_ viewController: UIViewController) {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

//MARK: - PolicySelectionViewControllerDelegate
extension SettingsCoordinator: PolicySelectionViewControllerDelegate {
    func newPolicySelected(_ viewController: PolicySelectionViewController, newPolicy: NotificationPolicy) {
        self.setting.activeSubscription?.policyRaw = newPolicy.subscriptionPolicy.rawValue
        try? self.appContext.managedObjectContext.save()
    }
}
