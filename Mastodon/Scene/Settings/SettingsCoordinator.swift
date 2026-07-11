// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import AuthenticationServices
import MastodonCore
import MastodonSDK
import Combine
import MetaTextKit
import MastodonUI

protocol SettingsCoordinatorDelegate: AnyObject {
    func logout(_ user: MastodonAuthentication, presentingFrom viewController: UIViewController)
    func openGithubURL(_ settingsCoordinator: SettingsCoordinator)
    func openPrivacyURL(_ settingsCoordinator: SettingsCoordinator)
    func openProfileSettingsURL(_ settingsCoordinator: SettingsCoordinator)
}

@MainActor
class SettingsCoordinator: NSObject, Coordinator {

    let presentedOn: UIViewController?
    var navigationFlow: NavigationFlow?

    weak var delegate: SettingsCoordinatorDelegate?
    public let settingsViewController: SettingsViewController

    var pushNotificationSettings: PushNotificationsSubscription.PushNotificationsSettings?
    let appContext: AppContext
    let authenticationBox: MastodonAuthenticationBox
    var disposeBag = Set<AnyCancellable>()
    let sceneCoordinator: SceneCoordinator

    init(presentedOn: UIViewController?, accountName: String, appContext: AppContext, authenticationBox: MastodonAuthenticationBox, sceneCoordinator: SceneCoordinator) {
        self.presentedOn = presentedOn
        self.appContext = appContext
        self.authenticationBox = authenticationBox
        self.sceneCoordinator = sceneCoordinator

        settingsViewController = SettingsViewController(accountName: accountName, domain: authenticationBox.domain)
        super.init()
        settingsViewController.delegate = self
        
        Task { [weak self] in
            guard let s = self else { return }
            let userAuthentication = s.authenticationBox.authentication
            let seed = Mastodon.Entity.DonationCampaign.donationSeed(username: userAuthentication.username, domain: userAuthentication.domain)
            do {
                let campaign = try await APIService.shared.getDonationCampaign(seed: seed, source: .menu).value
                
                await MainActor.run {
                    s.settingsViewController.donationCampaign = campaign
                    
                }
            } catch {
                // TODO: it would be nice to hide the Make Donation row if there was nothing to configure the donation screen with
            }
        }
    }

    func start() {
       // vestigial
    }
}

//MARK: - SettingsViewControllerDelegate
extension SettingsCoordinator: SettingsViewControllerDelegate {
    func done(_ viewController: UIViewController) {
        viewController.dismiss(animated: true)
    }

    func didSelect(_ viewController: UIViewController, entry: SettingsEntry) {
        guard let navigationController = viewController.navigationController else { return }
        switch entry {
            case .general:
            
                let generalSettingsViewController = GeneralSettingsViewController(appContext: appContext)
                generalSettingsViewController.delegate = self
            
                navigationController.pushViewController(generalSettingsViewController, animated: true)
            case .notifications:
                guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
                let notificationViewController = NotificationSettingsViewController(authBox: authBox)
                notificationViewController.delegate = self

                navigationController.pushViewController(notificationViewController, animated: true)
            case .privacySafety:
                let privacySafetyViewController = PrivacySafetyViewController(
                    appContext: appContext,
                    authenticationBox: authenticationBox,
                    coordinator: sceneCoordinator
                )
                navigationController.pushViewController(privacySafetyViewController, animated: true)
            case .serverDetails(let domain):
                let serverDetailsViewController = ServerDetailsViewController(domain: domain, appContext: appContext, authenticationBox: authenticationBox, sceneCoordinator: sceneCoordinator)
                serverDetailsViewController.delegate = self

            APIService.shared.instanceV2(domain: domain, authenticationBox: authenticationBox)
                    .sink { _ in

                    } receiveValue: { content in
                        serverDetailsViewController.update(with: content.value)
                    }
                    .store(in: &disposeBag)

            APIService.shared.extendedDescription(domain: domain, authenticationBox: authenticationBox)
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
                        
                        let donationFlow = NewDonationNavigationFlow(flowPresenter: viewController, campaign: donationCampaign, authenticationBox: s.authenticationBox, sceneCoordinator: s.sceneCoordinator)
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
            case .manageBetaFeatures:
                let betaTestSettingsViewController = BetaTestSettingsViewController()
            
                navigationController.pushViewController(betaTestSettingsViewController, animated: true)
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

//MARK: - GeneralSettingsViewControllerDelegate
extension SettingsCoordinator: GeneralSettingsViewControllerDelegate {
    
    func save(_ viewController: UIViewController, viewModel: GeneralSettingsViewModel) {
        UserDefaults.shared.customUserInterfaceStyle = viewModel.selectedAppearence.interfaceStyle
        UserDefaults.shared.preferredStaticEmoji = viewModel.playAnimations == false
        UserDefaults.shared.preferredStaticAvatar = viewModel.playAnimations == false
        UserDefaults.shared.preferredUsingDefaultBrowser = viewModel.selectedOpenLinks == .browser
    }
    
    func showLanguagePicker(_ viewModel: GeneralSettingsViewModel, onLanguageSelected: @escaping OnLanguageSelected) {
        let viewController = LanguagePickerViewController(onLanguageSelected: onLanguageSelected)
        settingsViewController.navigationController?.pushViewController(viewController, animated: true)
    }
}

//MARK: - NotificationSettingsViewControllerDelegate
extension SettingsCoordinator: NotificationSettingsViewControllerDelegate {
    func showPolicyList(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel) {
        let policyListViewController = PolicySelectionViewController(viewModel: viewModel)
        policyListViewController.delegate = self

        settingsViewController.navigationController?.pushViewController(policyListViewController, animated: true)
    }

    func viewWillDisappear(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel) {

        guard let newSettings = viewModel.settingsToRegister else { return }
        
        Task {
            try await BodegaPersistence.PushNotifications.savePendingSubscriptionSettings(newSettings, for: authenticationBox)
            NotificationService.shared.requestUpdate(
                .singleAccount(authenticationBox)
            )
        }
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
        guard let newQueryDataPolicy = Mastodon.API.Subscriptions.QueryData.Policy(rawValue: newPolicy.subscriptionPolicy.rawValue) else { return }
        pushNotificationSettings = PushNotificationsSubscription.PushNotificationsSettings(pushNotificationsFrom: newQueryDataPolicy, mentions: pushNotificationSettings?.mentions, boosts: pushNotificationSettings?.boosts, favorites: pushNotificationSettings?.favorites, newFollowers: pushNotificationSettings?.newFollowers, followRequests: pushNotificationSettings?.followRequests, polls: pushNotificationSettings?.polls)
    }
}

//MARK: - ServerDetailsViewControllerDelegate
extension SettingsCoordinator: ServerDetailsViewControllerDelegate {
    
}

extension SettingsCoordinator: AboutInstanceViewControllerDelegate {
    @MainActor
    func showAdminAccount(_ viewController: AboutInstanceViewController, account: Mastodon.Entity.Account) {
        Task {
            guard let myAccount = authenticationBox.cachedAccount else { return }
            let profile: ProfileType = {
                if account.acctWithDomain == myAccount.acctWithDomain {
                    .me(account)
                } else {
                    .notMe(me: myAccount, displayAccount: account, relationship: nil)
                }
            }()
            assertionFailure("no longer implemented")
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
            assertionFailure("no longer implemented")
                guard let url = URL(string: url) else { return }
            case .mention(_, _, let userInfo):
            assertionFailure("no longer implemented")
                guard let href = userInfo?["href"] as? String,
                      let url = URL(string: href) else { return }
            case .hashtag(_, let hashtag, _):
                let tag = Mastodon.Entity.Tag(name: hashtag, url: "")
            assertionFailure("no longer implemented")
            case .email(let email, _):
                if let emailUrl = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(emailUrl) {
                    UIApplication.shared.open(emailUrl)
                }
            case .emoji:
                break
        }
    }


}
