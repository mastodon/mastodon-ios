// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct MediaBadge<Content: View>: View {
    private var _isExpanded: Binding<Bool>?
    private let content: Content
    private var isExpanded: Bool {
        _isExpanded?.wrappedValue ?? false
    }

    init(isExpanded: Binding<Bool>? = nil, @ViewBuilder content: () -> Content) {
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        // need the VStack (or some other kind of containing view) to
        // ensure the transition animations work properly
        // Is this a bug? Is it intended behavior? I have no clue
        HStack {
            content
            if isExpanded {
                Spacer(minLength: 0)
            }
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, isExpanded ? 8 : 2)
        .foregroundColor(.white)
        .tint(.white)
        .background(Color.black.opacity(0.7))
        .cornerRadius(3)
        .overlay(
            .white.opacity(0.5),
            in: RoundedRectangle(cornerRadius: 3)
                .inset(by: -0.5)
                .stroke(lineWidth: 0.5)
        )
        // this is not accessible, but the badge UI is not shown to accessibility tools at the moment
        .onTapGesture {
            _isExpanded?.wrappedValue.toggle()
        }
        .accessibilityHidden(true)
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
