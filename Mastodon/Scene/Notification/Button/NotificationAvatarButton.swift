//
//  NotificationAvatarButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-21.
//

import UIKit
import FLAnimatedImage

final class NotificationAvatarButton: AvatarButton {

    // Size fixed
    static let containerSize = CGSize(width: 35, height: 35)
    static let badgeImageViewSize = CGSize(width: 24, height: 24)
    static let badgeImageMaskSize = CGSize(width: badgeImageViewSize.width + 4, height: badgeImageViewSize.height + 4)

    let badgeImageView: UIImageView = {
        let imageView = RoundedImageView()
        imageView.contentMode = .center
        imageView.isOpaque = true
        imageView.layer.shouldRasterize = true
        imageView.layer.rasterizationScale = UIScreen.main.scale
        return imageView
    }()

    override func _init() {
        super._init()

        avatarImageSize = CGSize(width: 35, height: 35)

        let path: CGPath = {
            let path = CGMutablePath()
            path.addRect(CGRect(origin: .zero, size: NotificationAvatarButton.containerSize))
            let x: CGFloat = {
                if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                    return -0.5 * NotificationAvatarButton.badgeImageMaskSize.width
                } else {
                    return NotificationAvatarButton.containerSize.width - 0.5 * NotificationAvatarButton.badgeImageMaskSize.width
                }
            }()
            path.addPath(UIBezierPath(
                ovalIn: CGRect(
                    x: x,
                    y: NotificationAvatarButton.containerSize.height - 0.5 * NotificationAvatarButton.badgeImageMaskSize.width,
                    width: NotificationAvatarButton.badgeImageMaskSize.width,
                    height: NotificationAvatarButton.badgeImageMaskSize.height
                )
            ).cgPath)
            return path
        }()

        let maskShapeLayer = CAShapeLayer()
        maskShapeLayer.backgroundColor = UIColor.black.cgColor
        maskShapeLayer.fillRule = .evenOdd
        maskShapeLayer.path = path
        avatarImageView.layer.mask = maskShapeLayer

        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeImageView)
        NSLayoutConstraint.activate([
            badgeImageView.centerXAnchor.constraint(equalTo: trailingAnchor),
            badgeImageView.centerYAnchor.constraint(equalTo: bottomAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: NotificationAvatarButton.badgeImageViewSize.width).priority(.required - 1),
            badgeImageView.heightAnchor.constraint(equalToConstant: NotificationAvatarButton.badgeImageViewSize.height).priority(.required - 1),
        ])
    }

    override func updateAppearance() {
        super.updateAppearance()
        badgeImageView.alpha = primaryActionState.contains(.highlighted)  ? 0.6 : 1.0
    }

}

final class RoundedImageView: UIImageView {

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.masksToBounds = true
        layer.cornerRadius = bounds.width / 2
        layer.cornerCurve = .circular
    }
}
