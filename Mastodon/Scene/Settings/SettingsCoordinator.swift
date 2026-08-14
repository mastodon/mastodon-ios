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
}

@MainActor
class SettingsCoordinator: NSObject, Coordinator {

    let presentedOn: UIViewController?

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
            assertionFailure("migrating to SettingsNavigationView")
            break

            case .notifications:
            assertionFailure("migrating to SettingsNavigationView")
            break

            case .privacySafety:
            assertionFailure("migrating to SettingsNavigationView")
            break

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
            assertionFailure("migrating to DonationFlowView")
            break
            case .manageDonations:
                guard let url = URL(string: "https://sponsor.joinmastodon.org/donate/manage") else { return }
                let webViewController = WebViewController(WebViewModel(url: url))
                navigationController.pushViewController(webViewController, animated: true)
            case .aboutMastodon:
            assertionFailure("migrating to SettingsNavigationView")
                
            case .manageBetaFeatures:
            assertionFailure("migrating to SettingsNavigationView")
        }
    }
}

//MARK: - ASWebAuthenticationPresentationContextProviding

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
