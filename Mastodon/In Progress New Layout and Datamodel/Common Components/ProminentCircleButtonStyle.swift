// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset

struct ProminentCircleButtonStyle: ButtonStyle {
    let diameter: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .contentShape(.circle)
            .glassEffectIfAvailable(.regular(interactive: true), withTint: Asset.Colors.accent.swiftUIColor, in: .circle)
    }
}

extension ButtonStyle where Self == ProminentCircleButtonStyle {
    static func prominentCircle(diameter: CGFloat) -> ProminentCircleButtonStyle {
        ProminentCircleButtonStyle(diameter: diameter)
    }
}
