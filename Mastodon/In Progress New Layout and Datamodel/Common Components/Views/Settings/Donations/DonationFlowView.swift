// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

struct DonationFlowView: View {
    @State var viewModel: DonationViewModel
    @State var navigator = MastodonNavigationRouter()
    
    init(campaign: Mastodon.Entity.DonationCampaign?, presentationSource: Mastodon.Entity.DonationCampaign.DonationCampaignRequestSource) {
        viewModel = DonationViewModel(campaign: campaign, presentationSource: presentationSource)
    }
    
    var body: some View {
        @Bindable var navigator = navigator
        NavigationStack(path: $navigator.navigationPath) {
            DonationSelectionsView()
                .environment(viewModel)
                .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                    switch destination {
                    case .donations(let donationDestination):
                        switch donationDestination {
                        case .submitDonation(let url):
                            if let campaign = viewModel.campaign {
                                DonationPaymentWebview(url: url, campaign: campaign) { result in
                                    switch result {
                                    case .successful, .failed:
                                        navigator.push(.donations(.donationCompleted(result)))
                                    case .canceled:
                                        MastodonTabViewRouter.current.navigationRouterForCurrentTab().dismissCurrentModal()
                                    }
                                }
                            }
                        case .donationCompleted(let result):
                            DonationCompletionView(result: result)
                        }
                    default:
                        navigator.destinationView(destination, sceneCoordinator: nil)
                    }
                }
        }
        .environment(navigator)
    }
}

struct DonationPaymentWebview: UIViewControllerRepresentable {
   
    let url: URL
    let campaign: Mastodon.Entity.DonationCampaign
    let onResult: (DonationResult) -> ()
    
    func makeUIViewController(context: Context) -> NotifyingWebViewController {
        let vc = NotifyingWebViewController(WebViewModel(url: url))
        context.coordinator.observe(vc, campaign: campaign, onResult: onResult)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: NotifyingWebViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    static func dismantleUIViewController(_ vc: NotifyingWebViewController, coordinator: Coordinator) {
        coordinator.task?.cancel()
    }
    
    final class Coordinator {
        var task: Task<Void, Never>?
        func observe(_ vc: NotifyingWebViewController, campaign: Mastodon.Entity.DonationCampaign, onResult: @escaping (DonationResult) -> Void) {
            task = Task { @MainActor in
                for await redirect in vc.navigationEvents.dropFirst(1) {
                    guard let result = DonationResult(callbackUrl: redirect, campaign: campaign) else { continue }
                    onResult(result)
                    break
                }
                
            }
        }
    }
}

extension DonationResult {
    init?(callbackUrl: URL, campaign: Mastodon.Entity.DonationCampaign) {
        switch callbackUrl.lastPathComponent {
        case "success": Mastodon.Entity.DonationCampaign.didContribute(campaign.id)
            self = .successful(suggestedPost: campaign.donationSuccessPost)
        case "failure":
            self = .failed
        case "cancel":
            self = .canceled
        default:
            return nil
        }
    }
}
