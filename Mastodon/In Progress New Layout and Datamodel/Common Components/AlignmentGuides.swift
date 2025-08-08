// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import SwiftUI

private let _eight: CGFloat = 8

let spacingBetweenGutterAndContent: CGFloat = _eight
let standardPadding: CGFloat = _eight
let doublePadding: CGFloat = _eight * 2
let tinySpacing: CGFloat = _eight / 2

struct AvatarSize {
    static var large: CGFloat = 44
    static var small: CGFloat = 32
    static var tiny: CGFloat = 16
}

struct CornerRadius {
    static var standard: CGFloat = _eight
    static var small: CGFloat = _eight / 2
    static var tiny: CGFloat = 3
}

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
