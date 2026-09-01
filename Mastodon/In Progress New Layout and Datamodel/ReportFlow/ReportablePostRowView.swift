// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonUI
import MastodonAsset

struct ReportablePostRowView: View {
    @Environment(MastodonPostViewModel.self) private var viewModel
    @ScaledMetric private var checkBoxSize: CGFloat = 30
    @State var isSelected: Bool = true
    
    let layoutWidth: CGFloat
    let postPadding: CGFloat = standardPadding
    let spacingToCheckbox: CGFloat = standardPadding
    
    var body: some View {
        let contentWidth = max(1, layoutWidth - checkBoxSize - (postPadding * 2) - spacingToCheckbox)
        HStack(alignment: .top, spacing: spacingToCheckbox) {
            VStack(alignment: .trailing) {
                VisibilityAndTimestamp(referenceDate: viewModel.actionableCreatedAt, visibility: viewModel.actionablePostVisibility)
                MastodonPostContentStackView(contentWidth: contentWidth, actionHandler: nil, navigator: nil, filterContext: nil)
                    .environment(ContentConcealViewModel.alwaysShow)
            }
            .padding(postPadding)
            .background() {
                MastodonSecondaryBackground(fillInDarkModeOnly: true)
            }
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: checkBoxSize, height: checkBoxSize)
                .foregroundStyle(isSelected ? Asset.Colors.accent.swiftUIColor : .secondary)
        }
    }
}

#if DEBUG
#Preview("Reportable post row") {
    ReportablePostRowView(layoutWidth: 300)
        .environment(PostPreviewModel.basicPost.postViewModel())
        .environment(TimestampUpdater.timestamper(withInterval: 60))
        .padding()
}
#endif
