//
//  AvatarButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-21.
//

import os.log
import UIKit

class AvatarButton: UIControl {

    // UIControl.Event - Application: 0x0F000000
    static let primaryAction = UIControl.Event(rawValue: 1 << 25)     // 0x01000000
    var primaryActionState: UIControl.State = .normal

    var avatarImageSize = CGSize(width: 42, height: 42)
    let avatarImageView = AvatarImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    func _init() {
        avatarImageView.frame = bounds
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }

    func updateAppearance() {
        avatarImageView.alpha = primaryActionState.contains(.highlighted)  ? 0.6 : 1.0
    }
    
}

extension AvatarButton {

    override var intrinsicContentSize: CGSize {
        return avatarImageSize
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }

        updateState(touch: touch, event: event)
        return super.beginTracking(touch, with: event)
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }

        updateState(touch: touch, event: event)
        return super.continueTracking(touch, with: event)
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
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

    override func cancelTracking(with event: UIEvent?) {
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

