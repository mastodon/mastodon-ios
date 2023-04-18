// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct MediaBadge<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // need the VStack (or some other kind of containing view) to
        // ensure the transition animations work properly
        // Is this a bug? Is it intended behavior? I have no clue
        HStack {
            content
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .foregroundColor(.white)
        .tint(.white)
        .background(Color.black.opacity(0.7))
        .cornerRadius(3)
        .accessibilityHidden(true)
    }
}

extension MediaBadge where Content == Text {
    init(_ text: String) {
        self.init {
            Text(text)
        }
    }
}

struct MediaBadge_Previews: PreviewProvider {
    static var previews: some View {
        MediaBadge {
            Button("ALT") {}
        }

        MediaBadge {
            Button("GIF") {}
        }

        MediaBadge {
            Text("01:24")
                .monospacedDigit()
        }
    }
}
