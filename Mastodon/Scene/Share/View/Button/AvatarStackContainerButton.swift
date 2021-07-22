//
//  AvatarStackContainerButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import os.log
import UIKit
import FLAnimatedImage

final class AvatarStackedImageView: AvatarImageView { }

// MARK: - AvatarConfigurableView
extension AvatarStackedImageView: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { CGSize(width: 28, height: 28) }
    static var configurableAvatarImageCornerRadius: CGFloat { 4 }
    var configurableAvatarImageView: FLAnimatedImageView? { self }
}

final class AvatarStackContainerButton: UIControl {
    
    static let containerSize = CGSize(width: 42, height: 42)
    static let avatarImageViewSize = CGSize(width: 28, height: 28)
    static let avatarImageViewCornerRadius: CGFloat = 4
    static let maskOffset: CGFloat = 2
    
    // UIControl.Event - Application: 0x0F000000
    static let primaryAction = UIControl.Event(rawValue: 1 << 25)     // 0x01000000
    var primaryActionState: UIControl.State = .normal

    let topLeadingAvatarStackedImageView = AvatarStackedImageView()
    let bottomTrailingAvatarStackedImageView = AvatarStackedImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AvatarStackContainerButton {
    
    private func _init() {
        topLeadingAvatarStackedImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topLeadingAvatarStackedImageView)
        NSLayoutConstraint.activate([
            topLeadingAvatarStackedImageView.topAnchor.constraint(equalTo: topAnchor),
            topLeadingAvatarStackedImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topLeadingAvatarStackedImageView.widthAnchor.constraint(equalToConstant: AvatarStackedImageView.configurableAvatarImageSize.width).priority(.defaultHigh),
            topLeadingAvatarStackedImageView.heightAnchor.constraint(equalToConstant: AvatarStackedImageView.configurableAvatarImageSize.height).priority(.defaultHigh),
        ])

        bottomTrailingAvatarStackedImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomTrailingAvatarStackedImageView)
        NSLayoutConstraint.activate([
            bottomTrailingAvatarStackedImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomTrailingAvatarStackedImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomTrailingAvatarStackedImageView.widthAnchor.constraint(equalToConstant: AvatarStackedImageView.configurableAvatarImageSize.width).priority(.defaultHigh),
            bottomTrailingAvatarStackedImageView.heightAnchor.constraint(equalToConstant: AvatarStackedImageView.configurableAvatarImageSize.height).priority(.defaultHigh),
        ])

        // mask topLeadingAvatarStackedImageView
        let offset: CGFloat = 2
        let path: CGPath = {
            let path = CGMutablePath()
            path.addRect(CGRect(origin: .zero, size: AvatarStackContainerButton.avatarImageViewSize))
            let mirrorScale: CGFloat = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? -1 : 1
            path.addPath(UIBezierPath(
                roundedRect: CGRect(
                    x: mirrorScale * (AvatarStackContainerButton.containerSize.width - AvatarStackContainerButton.avatarImageViewSize.width - offset),
                    y: AvatarStackContainerButton.containerSize.height - AvatarStackContainerButton.avatarImageViewSize.height - offset,
                    width: AvatarStackContainerButton.avatarImageViewSize.width,
                    height: AvatarStackContainerButton.avatarImageViewSize.height
                ),
                cornerRadius: AvatarStackedImageView.configurableAvatarImageCornerRadius + 1    // 1pt overshoot
            ).cgPath)
            return path
        }()
        let maskShapeLayer = CAShapeLayer()
        maskShapeLayer.backgroundColor = UIColor.black.cgColor
        maskShapeLayer.fillRule = .evenOdd
        maskShapeLayer.path = path
        topLeadingAvatarStackedImageView.layer.mask = maskShapeLayer
    }

    override var intrinsicContentSize: CGSize {
        return AvatarStackContainerButton.containerSize
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
            if AvatarStackContainerButton.isTouching(touch, view: self, event: event) {
                sendActions(for: AvatarStackContainerButton.primaryAction)
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

extension AvatarStackContainerButton {
    
    private func updateAppearance() {
        topLeadingAvatarStackedImageView.alpha = primaryActionState.contains(.highlighted)  ? 0.6 : 1.0
        bottomTrailingAvatarStackedImageView.alpha = primaryActionState.contains(.highlighted)  ? 0.6 : 1.0
    }
    
    private static func isTouching(_ touch: UITouch, view: UIView, event: UIEvent?) -> Bool {
        let location = touch.location(in: view)
        return view.point(inside: location, with: event)
    }
    
    private func resetState() {
        primaryActionState = .normal
    }
    
    private func updateState(touch: UITouch, event: UIEvent?) {
        primaryActionState = AvatarStackContainerButton.isTouching(touch, view: self, event: event) ? .highlighted : .normal
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AvatarStackContainerButton_Previews: PreviewProvider {

    static var previews: some View {
        UIViewPreview(width: 42) {
            let avatarStackContainerButton = AvatarStackContainerButton()
            avatarStackContainerButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                avatarStackContainerButton.widthAnchor.constraint(equalToConstant: 42),
                avatarStackContainerButton.heightAnchor.constraint(equalToConstant: 42),
            ])
            return avatarStackContainerButton
        }
        .previewLayout(.fixed(width: 42, height: 42))
    }

}

#endif

