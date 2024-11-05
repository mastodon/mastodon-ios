// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import SwiftUI

public enum DonationResult {
    case successful(suggestedPost: String)
    case failed
    case canceled
}

public enum DonationCompletionAction {
    case makePost(string: String)
    case close
}

class DonationCompletionViewController: UIHostingController<
    DonationCompletionView
>
{

    init(
        _ result: DonationResult,
        completion: @escaping (DonationCompletionAction) -> Void
    ) {
        super.init(
            rootView: DonationCompletionView(
                result: result, completion: completion)
        )
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct DonationCompletionView: View {

    let result: DonationResult
    let completion: (DonationCompletionAction) -> Void

    init(
        result: DonationResult,
        completion: @escaping (DonationCompletionAction) -> Void
    ) {
        self.result = result
        self.completion = completion
    }

    var suggestedPost: String {
        switch result {
        case .successful(let suggestedPost):
            return suggestedPost
        case .failed, .canceled:
            return "No suggested post"
        }
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
        Text(L10n.Scene.Donation.Success.title)
            .font(.largeTitle)
            .bold()
            .multilineTextAlignment(.center)
    }
    @ViewBuilder var subMessage: some View {
        Text(L10n.Scene.Donation.Success.subtitle)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder var messageImage: some View {
        Image(uiImage: Asset.Asset.donationThankYou.image)
            .resizable()
            .scaledToFit()
    }

    @ViewBuilder var buttons: some View {
        VStack {
            Button(action: {
                completion(.makePost(string: suggestedPost))
            }) {
                HStack {
                    Spacer()
                    Text(L10n.Scene.Donation.Success.shareButtonTitle)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(DonationButtonStyle(type: .action, filled: true))
            Button(action: {
                completion(.close)
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
