//
//  AvatarBarButtonItem.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-4.
//

import UIKit

final class AvatarBarButtonItem: UIBarButtonItem {

    static let avatarButtonSize = CGSize(width: 32, height: 32)

    let avatarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: avatarButtonSize.width).priority(.defaultHigh),
            button.heightAnchor.constraint(equalToConstant: avatarButtonSize.height).priority(.defaultHigh),
        ])
        return button
    }()
    
    override init() {
        super.init()
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AvatarBarButtonItem {
    
    private func _init() {
        customView = avatarButton
    }
    
}

extension AvatarBarButtonItem: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { return avatarButtonSize }
    static var configurableAvatarImageCornerRadius: CGFloat { return 4 }
    var configurableAvatarImageView: UIImageView? { return nil }
    var configurableAvatarButton: UIButton? { return avatarButton }
    var configurableVerifiedBadgeImageView: UIImageView? { return nil }
}
