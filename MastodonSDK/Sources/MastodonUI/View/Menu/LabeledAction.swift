// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import UIKit

public struct LabeledAction {
    public init(
        title: String,
        image: UIImage? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.image = image
        self.attributes = attributes
        self.state = state
        self.handler = handler
    }

    private let title: String
    private let image: UIImage?
    private let attributes: UIMenuElement.Attributes
    private let state: UIMenuElement.State
    private let handler: () -> Void

    public var menuElement: UIMenuElement {
        UIAction(
            title: title,
            image: image,
            identifier: nil,
            discoverabilityTitle: nil,
            attributes: attributes,
            state: .off
        ) { _ in
            handler()
        }
    }

    public var accessibilityCustomAction: UIAccessibilityCustomAction {
        UIAccessibilityCustomAction(name: title, image: image) { _ in
            handler()
            return true
        }
    }
}

extension LabeledAction {
    public init(
        title: String,
        asset: ImageAsset? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.image = asset?.image.withRenderingMode(.alwaysTemplate)
        self.attributes = attributes
        self.state = state
        self.handler = handler
    }

}


