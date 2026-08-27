// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import SwiftUI

public enum DonationResult {
    case successful(suggestedPost: String)
    case failed
    case canceled
}

struct DonationCompletionView: View {

    let result: DonationResult

    init(
        result: DonationResult
    ) {
        self.result = result
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 15) {
                Spacer()
                topMessage
                subMessage
                messageImage
                Spacer()
                buttons
            }
            .padding([.leading, .trailing], 30)
            .frame(maxWidth: geometry.size.width)
        }
    }

    @ViewBuilder var topMessage: some View {
        let title = {
            switch result {
            case .successful:
                L10n.Scene.Donation.Success.title
            case .failed:
                L10n.Scene.Donation.Success.serverErrorTitle
            case .canceled:
                "Canceled"
            }
        }()
        
        Text(title)
            .font(.largeTitle)
            .bold()
            .multilineTextAlignment(.center)
    }
    @ViewBuilder var subMessage: some View {
        let message = {
            switch result {
            case .successful:
                L10n.Scene.Donation.Success.subtitle
            case .failed:
                L10n.Scene.Donation.Success.serverErrorMessage
            case .canceled:
                "Canceled"
            }
        }()
        Text(message)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder var messageImage: some View {
        switch result {
        case .successful:
            Image(uiImage: Asset.Asset.donationThankYou.image)
                .resizable()
                .scaledToFit()
        case .failed:
            EmptyView()
        case .canceled:
            EmptyView()
        }
    }

    @ViewBuilder var buttons: some View {
        VStack {
            switch result {
            case .successful(let suggestedPost):
                Button(action: {
                    guard let authBox = AuthenticationObserver.shared.currentActiveUser else { return }
                    let currentNavigator = MastodonTabViewRouter.current.navigationRouterForCurrentTab()
                    currentNavigator.dismissCurrentModal()
                    let composeViewModel = ComposeViewModel(
                        authenticationBox: authBox,
                        composeContext: .composeStatus(quoting: nil),
                        destination: .topLevel,
                        initialContent: suggestedPost
                    )
                    currentNavigator.presentSheet(.modalCompose(composeViewModel, nil), afterDeconflictionDelay: true)
                }) {
                    HStack {
                        Spacer()
                        Text(L10n.Scene.Donation.Success.shareButtonTitle)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(DonationButtonStyle(type: .action, filled: true))
            default:
                EmptyView()
            }
            
            Button(action: {
                let currentNavigator = MastodonTabViewRouter.current.navigationRouterForCurrentTab()
                currentNavigator.dismissCurrentModal()
            }) {
                HStack {
                    Spacer()
                    Text(L10n.Common.Controls.Actions.done)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(DonationButtonStyle(type: .action, filled: false))
        }
    }
}
