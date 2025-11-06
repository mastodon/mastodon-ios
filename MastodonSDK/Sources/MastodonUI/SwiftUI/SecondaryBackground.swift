// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI

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
