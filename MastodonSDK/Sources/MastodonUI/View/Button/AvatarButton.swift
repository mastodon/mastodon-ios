//
//  AvatarButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-21.
//

import os.log
import UIKit
import MastodonLocalization

open class AvatarButton: UIControl {

    // UIControl.Event - Application: 0x0F000000
    static let primaryAction = UIControl.Event(rawValue: 1 << 25)     // 0x01000000
    public var primaryActionState: UIControl.State = .normal

    public var size = CGSize(width: 46, height: 46)
    public let avatarImageView = AvatarImageView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    open func _init() {
        avatarImageView.frame = bounds
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarImageView)
        avatarImageView.pinToParent()
        
        isAccessibilityElement = true
        accessibilityLabel = L10n.Common.Controls.Status.showUserProfile
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateAppearance()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }

    open func updateAppearance() {
        avatarImageView.alpha = primaryActionState.contains(.highlighted)  ? 0.6 : 1.0
    }
    
}

extension AvatarButton {

    public override var intrinsicContentSize: CGSize {
        return size
    }

    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }

        updateState(touch: touch, event: event)
        return super.beginTracking(touch, with: event)
    }

    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }

        updateState(touch: touch, event: event)
        return super.continueTracking(touch, with: event)
    }

    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        defer { updateAppearance() }
        resetState()

        if let touch = touch {
            if AvatarButton.isTouching(touch, view: self, event: event) {
                sendActions(for: AvatarButton.primaryAction)
            } else {
                // do nothing
            }
        }

        super.endTracking(touch, with: event)
    }

    public override func cancelTracking(with event: UIEvent?) {
        defer { updateAppearance() }

        resetState()
        super.cancelTracking(with: event)
    }

}

extension AvatarButton {

    private static func isTouching(_ touch: UITouch, view: UIView, event: UIEvent?) -> Bool {
        let location = touch.location(in: view)
        return view.point(inside: location, with: event)
    }

    private func resetState() {
        primaryActionState = .normal
    }

    private func updateState(touch: UITouch, event: UIEvent?) {
        primaryActionState = AvatarButton.isTouching(touch, view: self, event: event) ? .highlighted : .normal
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AvatarButton_Previews: PreviewProvider {

    static var previews: some View {
        UIViewPreview(width: 42) {
            let avatarButton = AvatarButton()
            avatarButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                avatarButton.widthAnchor.constraint(equalToConstant: 42),
                avatarButton.heightAnchor.constraint(equalToConstant: 42),
            ])
            return avatarButton
        }
        .previewLayout(.fixed(width: 42, height: 42))
    }

}

#endif

