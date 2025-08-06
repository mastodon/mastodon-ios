// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonSDK

struct DonationPromptBanner: View {
    let campaign: Mastodon.Entity.DonationCampaign
    let close: () -> ()
    let showDonationDialog: () -> ()

    var body: some View {
        ZStack(alignment: .trailing) {
            Asset.Colors.Secondary.container.swiftUIColor
            Image(uiImage: Asset.Asset.scribble.image)
                .opacity(0.08)
                .scaledToFill()
            HStack(spacing: 0) {
                Text(campaign.bannerMessage + " ").foregroundStyle(Asset.Colors.Secondary.onContainer.swiftUIColor) + Text(campaign.bannerButtonText).bold().underline().foregroundStyle(Asset.Colors.goldenrod.swiftUIColor)
                Spacer(minLength: doublePadding * 2)
                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .tint(Asset.Colors.Secondary.onContainer.swiftUIColor)
                }
            }
            .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: doublePadding, trailing: standardPadding))
        }
        .environment(\.colorScheme, .dark)
        .onTapGesture {
            showDonationDialog()
        }
    }
}
