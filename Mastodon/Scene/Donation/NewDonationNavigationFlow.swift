// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonLocalization
import MastodonSDK
import UIKit

@MainActor
class NewDonationNavigationFlow: NavigationFlow {

    private let campaign: DonationCampaignViewModel
    private let authenticationBox: MastodonAuthenticationBox
    private let sceneCoordinator: SceneCoordinator

    init(
        flowPresenter: NavigationFlowPresenter,
        campaign: DonationCampaignViewModel,
        authenticationBox: MastodonAuthenticationBox, sceneCoordinator: SceneCoordinator
    ) {
        self.campaign = campaign
        self.authenticationBox = authenticationBox
        self.sceneCoordinator = sceneCoordinator
        super.init(flowPresenter: flowPresenter)
    }

    override func startFlow() {
        showDonationOptionsController()
    }

    private func showDonationOptionsController() {
        let optionsController = DonationViewController(campaign: campaign) {
            [weak self] attemptedDonation in
            guard let s = self else { return }
            if let attemptedDonation {
                s.showDonationPaymentWebview(
                    attemptedDonation, campaign: s.campaign)
            } else {
                s.dismissFlow()
            }
        }
        
        if flowPresenter is UINavigationController {
            flowPresenter.show(optionsController, preferredDetents: [.medium()])
        } else {
            let navController = UINavigationController(rootViewController: optionsController)
            flowPresenter.show(navController, preferredDetents: [.medium()])
        }
    }

    private func showDonationPaymentWebview(
        _ paymentURL: URL, campaign: DonationCampaignViewModel
    ) {
        let model = WebViewModel(url: paymentURL)
        let viewController = NotifyingWebViewController(model)

        Task { [weak self] in
            for await url in viewController.navigationEvents.dropFirst(1) {
                self?.handleDonationCompletion(url, campaign: campaign)
                break
            }
        }
        flowPresenter.show(viewController, preferredDetents: [.large()])
    }

    private func handleDonationCompletion(
        _ response: URL, campaign: DonationCampaignViewModel
    ) {
        let result: DonationResult
        let responseString = response.lastPathComponent
        switch responseString {
        case "success":
            result = .successful(suggestedPost: campaign.donationSuccessPost)
            showDonationCompletionMessage(result)
            Mastodon.Entity.DonationCampaign.didContribute(campaign.id)
        case "failure":
            let alert = UIAlertController(
                title: L10n.Scene.Donation.Success.serverErrorTitle,
                message: L10n.Scene.Donation.Success.serverErrorMessage,
                preferredStyle: .actionSheet)
            flowPresenter.showAlert(alert)
            result = .failed
        case "cancel":
            result = .canceled
            dismissFlow()
            break
        default:
            return
        }
    }

    private func showDonationCompletionMessage(_ result: DonationResult) {
        let viewController = DonationCompletionViewController(result) {
            [weak self] completionEvent in
            switch completionEvent {
            case .makePost(let suggestedPost):
                self?.composeDonationSuccessPost(suggestedPost)
            case .close:
                self?.dismissFlow()
            }
        }
        flowPresenter.show(viewController, preferredDetents: [.large()])
    }

    private func composeDonationSuccessPost(_ suggestedText: String) {
        let composeViewModel = ComposeViewModel(
            authenticationBox: authenticationBox,
            composeContext: .composeStatus(quoting: nil),
            destination: .topLevel,
            initialContent: suggestedText
        )
        sceneCoordinator.present(
            scene: .compose(viewModel: composeViewModel),
            from: nil,
            transition: .modal(animated: true, completion: nil)
        )
    }

}
