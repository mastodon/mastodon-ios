// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import SwiftUI

private let _eight: CGFloat = 8

let spacingBetweenGutterAndContent: CGFloat = _eight
let standardPadding: CGFloat = _eight
let doublePadding: CGFloat = _eight * 2
let tinySpacing: CGFloat = _eight / 2

let maxFeedContentWidth: CGFloat = 700

struct ButtonPadding {
    static var vertical: CGFloat = 3
    static var horizontal = _eight
    static var capsuleHorizontal: CGFloat = _eight * 2
}

struct PollPadding {
    static var optionPadding: CGFloat = 12
}

extension HorizontalAlignment {
    enum GutterAlign: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.leading]
        }
    }
    
    static let gutterAlign = HorizontalAlignment(GutterAlign.self)
}

extension Color {
    static var dimmingBackground = Color.black.opacity(0.6)
}
