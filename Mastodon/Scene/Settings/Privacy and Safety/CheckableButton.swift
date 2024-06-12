// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset

struct CheckableButton: View {
    let text: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                Spacer()
                if isChecked {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
                }
            }
        }
    }
}
