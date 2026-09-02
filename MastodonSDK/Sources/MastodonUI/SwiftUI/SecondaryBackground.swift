// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset

public struct MastodonSecondaryBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    public let fillInDarkModeOnly: Bool
    
    public init(fillInDarkModeOnly: Bool) {
        self.fillInDarkModeOnly = fillInDarkModeOnly
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                AnyShapeStyle(fillColor)
            )
            .stroke(.separator)
    }
    
    var fillColor: Color {
        if fillInDarkModeOnly && colorScheme != .dark {
            return .clear
        } else {
            return Color(UIColor.secondarySystemBackground)
        }
    }
}

public struct MastodonSelectionBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    public let isSelected: Bool
    
    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                AnyShapeStyle(fillColor)
            )
            .stroke(isSelected ? AnyShapeStyle(Asset.Colors.accent.swiftUIColor) : AnyShapeStyle(.separator))
    }
    
    var fillColor: Color {
        if isSelected {
            switch colorScheme {
            case .dark:
                return Color(UIColor.secondarySystemBackground)
            case .light:
                return Color(UIColor.systemBackground)

            @unknown default:
                return Color(UIColor.systemBackground)
            }
        } else {
            return .clear
        }
    }
}
