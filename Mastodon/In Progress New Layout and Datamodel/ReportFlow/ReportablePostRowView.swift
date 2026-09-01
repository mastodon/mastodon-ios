// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonUI
import MastodonAsset

struct ReportablePostRowView: View {
    @Environment(MastodonPostViewModel.self) private var viewModel
    
    let layoutWidth: CGFloat
    let canChangeSelection: Bool
    @Binding var isSelected: Bool
    
    @ScaledMetric private var checkBoxSize: CGFloat = 30
    let postPadding: CGFloat = standardPadding
    let spacingToCheckbox: CGFloat = standardPadding
    
    var body: some View {
        let contentWidth = max(1, layoutWidth - checkBoxSize - (postPadding * 2) - spacingToCheckbox)
        HStack(alignment: .top, spacing: spacingToCheckbox) {
            VStack(alignment: .trailing) {
                VisibilityAndTimestamp(referenceDate: viewModel.actionableCreatedAt, visibility: viewModel.actionablePostVisibility)
                MastodonPostContentStackView(contentWidth: contentWidth, actionHandler: nil, navigator: nil, filterContext: nil)
                    .environment(ContentConcealViewModel.alwaysShow)
                    .allowsHitTesting(false)
            }
            .padding(postPadding)
            .background() {
                MastodonSelectionBackground(isSelected: isSelected)
            }
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: checkBoxSize, height: checkBoxSize)
                .foregroundStyle(checkboxColor)
        }
    }
    
    var checkboxColor: Color {
        isSelected && canChangeSelection ? Asset.Colors.accent.swiftUIColor : .secondary
    }
}

#if DEBUG
#Preview("Unselected post row") {
    ReportablePostRowView(layoutWidth: 300,
                          canChangeSelection: true,
                          isSelected: .constant(false))
        .environment(PostPreviewModel.basicPost.postViewModel())
        .environment(TimestampUpdater.timestamper(withInterval: 60))
        .padding()
}

#Preview("Selected post row") {
    ReportablePostRowView(layoutWidth: 300,
                          canChangeSelection: true,
                          isSelected: .constant(true))
    .environment(PostPreviewModel.basicPost.postViewModel())
    .environment(TimestampUpdater.timestamper(withInterval: 60))
    .padding()
}

#Preview("Selected locked post row") {
    ReportablePostRowView(layoutWidth: 300,
                          canChangeSelection: false,
                          isSelected: .constant(true))
    .environment(PostPreviewModel.basicPost.postViewModel())
    .environment(TimestampUpdater.timestamper(withInterval: 60))
    .padding()
}
#endif
