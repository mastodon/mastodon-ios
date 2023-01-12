// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

extension NSObject {
    @inlinable public var attributedAccessibilityLabel: AttributedString? {
        get { accessibilityAttributedLabel.map(AttributedString.init) }
        set { accessibilityAttributedLabel = newValue.map(NSAttributedString.init) }
    }
    
    @inlinable public var attributedAccessibilityValue: AttributedString? {
        get { accessibilityAttributedValue.map(AttributedString.init) }
        set { accessibilityAttributedValue = newValue.map(NSAttributedString.init) }
    }
    
    @inlinable public var attributedAccessibilityHint: AttributedString? {
        get { accessibilityAttributedHint.map(AttributedString.init) }
        set { accessibilityAttributedHint = newValue.map(NSAttributedString.init) }
    }

    @inlinable public var attributedAccessibilityUserInputLabels: [AttributedString]! {
        get { accessibilityAttributedUserInputLabels?.map(AttributedString.init) }
        set { accessibilityAttributedUserInputLabels = newValue?.map(NSAttributedString.init) }
    }
}
