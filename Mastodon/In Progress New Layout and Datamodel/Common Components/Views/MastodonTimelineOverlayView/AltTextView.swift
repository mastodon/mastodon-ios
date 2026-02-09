// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonUI
import SwiftUI

struct AltTextView: View {
    let altTextString: String
    let frameSize: CGSize
  
    var body: some View {
        VStack {
            Spacer()
                .frame(maxHeight: .infinity)
            ScrollView {
                Text(altTextString)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: min(300, frameSize.width * 0.85))
            }
            .frame(maxHeight: frameSize.height * 0.8)
            .environment(\.colorScheme, .dark)
            .background() {
                RoundedRectangle(cornerRadius: CornerRadius.standard)
                    .fill(.black.opacity(0.6))
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
                .frame(maxHeight: .infinity)
        }
    }
}
