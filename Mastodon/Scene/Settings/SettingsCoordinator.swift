// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import AuthenticationServices
import MastodonCore
import CoreDataStack
import MastodonSDK
import Combine
import MetaTextKit
import MastodonUI

protocol SettingsCoordinatorDelegate: AnyObject {
    func logout(_ settingsCoordinator: SettingsCoordinator)
    func openGithubURL(_ settingsCoordinator: SettingsCoordinator)
    func openPrivacyURL(_ settingsCoordinator: SettingsCoordinator)
    func openProfileSettingsURL(_ settingsCoordinator: SettingsCoordinator)
}

class SettingsCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    let presentedOn: UIViewController
    var navigationFlow: NavigationFlow?

    weak var delegate: SettingsCoordinatorDelegate?
    private let settingsViewController: SettingsViewController

    let setting: Setting
    let appContext: AppContext
    let authContext: AuthContext
    var disposeBag = Set<AnyCancellable>()
    let sceneCoordinator: SceneCoordinator

    init(presentedOn: UIViewController, accountName: String, setting: Setting, appContext: AppContext, authContext: AuthContext, sceneCoordinator: SceneCoordinator) {
        self.presentedOn = presentedOn
        navigationController = UINavigationController()
        self.setting = setting
        self.appContext = appContext
        self.authContext = authContext
        self.sceneCoordinator = sceneCoordinator

        settingsViewController = SettingsViewController(accountName: accountName, domain: authContext.mastodonAuthenticationBox.domain)
        
        super.init()
        
        Task { [weak self] in
            guard let s = self else { return }
            let userAuthentication = s.authContext.mastodonAuthenticationBox.authentication
            let seed = Mastodon.Entity.DonationCampaign.donationSeed(username: userAuthentication.username, domain: userAuthentication.domain)
            do {
                let campaign = try await s.appContext.apiService.getDonationCampaign(seed: seed, source: nil).value
                
                await MainActor.run {
                    s.settingsViewController.donationCampaign = campaign
                    
                }
            } catch {
                // TODO: it would be nice to hide the Make Donation row if there was nothing to configure the donation screen with
            }
        }
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
            
                let generalSettingsViewController = GeneralSettingsViewController(appContext: appContext, setting: setting)
                generalSettingsViewController.delegate = self
            
                navigationController.pushViewController(generalSettingsViewController, animated: true)
            case .notifications:

                let currentSetting = appContext.settingService.currentSetting.value
                let notificationsEnabled = appContext.notificationService.isNotificationPermissionGranted.value
                let notificationViewController = NotificationSettingsViewController(currentSetting: currentSetting, notificationsEnabled: notificationsEnabled)
                notificationViewController.delegate = self

                navigationController.pushViewController(notificationViewController, animated: true)
            case .privacySafety:
                let privacySafetyViewController = PrivacySafetyViewController(
                    appContext: appContext,
                    authContext: authContext,
                    coordinator: sceneCoordinator
                )
                navigationController.pushViewController(privacySafetyViewController, animated: true)
            case .serverDetails(let domain):
                let serverDetailsViewController = ServerDetailsViewController(domain: domain, appContext: appContext, authContext: authContext, sceneCoordinator: sceneCoordinator)
                serverDetailsViewController.delegate = self

                appContext.apiService.instanceV2(domain: domain, authenticationBox: authContext.mastodonAuthenticationBox)
                    .sink { _ in

                    } receiveValue: { content in
                        serverDetailsViewController.update(with: content.value)
                    }
                    .store(in: &disposeBag)

                appContext.apiService.extendedDescription(domain: domain, authenticationBox: authContext.mastodonAuthenticationBox)
                    .sink { _ in

                    } receiveValue: { content in
                        serverDetailsViewController.updateFooter(with: content.value)
                    }
                    .store(in: &disposeBag)


                navigationController.pushViewController(serverDetailsViewController, animated: true)
            
            case .makeDonation:
                Task {
                    await MainActor.run { [weak self] in
                        guard let s = self, let donationCampaign = s.settingsViewController.donationCampaign else { return }
                        
                        let donationFlow = NewDonationNavigationFlow(flowPresenter: viewController, campaign: donationCampaign, appContext: s.appContext, authContext: s.authContext, sceneCoordinator: s.sceneCoordinator)
                        s.navigationFlow = donationFlow
                        donationFlow.presentFlow { [weak self] in
                            self?.navigationFlow = nil
                        }
                    }
                }
            case .manageDonations:
                guard let url = URL(string: "https://sponsor.joinmastodon.org/donate/manage") else { return }
                let webViewController = WebViewController(WebViewModel(url: url))
                navigationController.pushViewController(webViewController, animated: true)
            case .aboutMastodon:
                let aboutViewController = AboutViewController()
                aboutViewController.delegate = self

                navigationController.pushViewController(aboutViewController, animated: true)
            case .logout(_):
                delegate?.logout(self)
            case .toggleTestDonations:
                Mastodon.API.toggleTestingDonations()
                settingsViewController.tableView.reloadData()
            case .clearPreviousDonationCampaigns:
                Mastodon.Entity.DonationCampaign.forgetPreviousCampaigns()
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
    
    func showLanguagePicker(_ viewModel: GeneralSettingsViewModel, onLanguageSelected: @escaping OnLanguageSelected) {
        let viewController = LanguagePickerViewController(onLanguageSelected: onLanguageSelected)
        navigationController.pushViewController(viewController, animated: true)
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

        //Show spinner?

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

//MARK: - ServerDetailsViewControllerDelegate
extension SettingsCoordinator: ServerDetailsViewControllerDelegate {
    
}

extension SettingsCoordinator: AboutInstanceViewControllerDelegate {
    @MainActor
    func showAdminAccount(_ viewController: AboutInstanceViewController, account: Mastodon.Entity.Account) {
        Task {
            await DataSourceFacade.coordinateToProfileScene(provider: viewController, account: account)
        }
    }
    
    func sendEmailToAdmin(_ viewController: AboutInstanceViewController, emailAddress: String) {
        if let emailUrl = URL(string: "mailto:\(emailAddress)"), UIApplication.shared.canOpenURL(emailUrl) {
            UIApplication.shared.open(emailUrl)
        }
    }
}

extension SettingsCoordinator: InstanceRulesViewControllerDelegate {
    
}

extension SettingsCoordinator: MetaLabelDelegate {
    @MainActor
    func metaLabel(_ metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        switch meta {
            case .url(_, _, let url, _):
                guard let url = URL(string: url) else { return }
                _ = sceneCoordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
            case .mention(_, _, let userInfo):
                guard let href = userInfo?["href"] as? String,
                      let url = URL(string: href) else { return }
                _ = sceneCoordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
            case .hashtag(_, let hashtag, _):
                let hashtagTimelineViewModel = HashtagTimelineViewModel(context: appContext, authContext: authContext, hashtag: hashtag)
                _ = sceneCoordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel), from: nil, transition: .show)
            case .email(let email, _):
                if let emailUrl = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(emailUrl) {
                    UIApplication.shared.open(emailUrl)
                }
            case .emoji:
                break
        }
    }


}
