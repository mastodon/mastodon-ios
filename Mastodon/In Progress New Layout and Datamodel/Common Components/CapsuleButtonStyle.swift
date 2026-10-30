// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset

struct CapsuleButtonStyle: ButtonStyle {
    
    enum Prominence {
        case prominent
        case subtle
        case neutral
    }
    
    private let prominence: Prominence
    private let isLarge: Bool
    
    init(_ prominence: Prominence, isLarge: Bool) {
        self.prominence = prominence
        self.isLarge = isLarge
    }
    
    func makeBody(configuration: Configuration) -> some View {
        if isLarge {
            configuration.label
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding([.horizontal], 12)
                .padding([.vertical], 14)
                .background(backgroundColor)
                .foregroundStyle(textColor)
                .controlSize(.small)
                .fontWeight(fontWeight)
                .clipShape(Capsule())
        } else {
            configuration.label
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding([.horizontal], 12)
                .padding([.vertical], 4)
                .background(backgroundColor)
                .foregroundStyle(textColor)
                .controlSize(.small)
                .fontWeight(fontWeight)
                .clipShape(Capsule())
        }
    }
    
    private var backgroundColor: Color {
        switch prominence {
        case .prominent:
            Asset.Colors.Button.userFollow.swiftUIColor
        case .subtle:
            Asset.Colors.Button.userFollowing.swiftUIColor
        case .neutral:
            .secondary.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch prominence {
        case .prominent:
                .white
        case .subtle, .neutral:
            Asset.Colors.Button.userFollowingTitle.swiftUIColor
        }
    }
    
    private var fontWeight: SwiftUICore.Font.Weight {
        switch prominence {
        case .prominent, .neutral:
            isLarge ? .bold : .regular
        case .subtle:
            isLarge ? .regular : .light
        }
    }
    
}

extension ButtonStyle where Self == CapsuleButtonStyle {
    static func prominentCapsule(isLarge: Bool) -> CapsuleButtonStyle {
        CapsuleButtonStyle(.prominent, isLarge: isLarge)
    }
    
    static func subtleCapsule(isLarge: Bool) -> CapsuleButtonStyle {
        CapsuleButtonStyle(.subtle, isLarge: isLarge)
    }
}
