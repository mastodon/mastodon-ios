//
//  HUDButton.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-11-24.
//

import UIKit
import MastodonUI

class HUDButton: UIView {

    static let height: CGFloat = 30

    let background: UIVisualEffectView = {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        backgroundView.alpha = 0.9
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = HUDButton.height * 0.5
        return backgroundView
    }()

    let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial)))

    let button: UIButton = {
        let button = HighlightDimmableButton()
        button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.imageView?.tintColor = .label
        return button
    }()

    init(configure: (UIButton) -> Void) {
        super.init(frame: .zero)

        configure(button)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    func _init() {
        translatesAutoresizingMaskIntoConstraints = false
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        background.pinToParent()
        vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.contentView.addSubview(vibrancyView)

        button.translatesAutoresizingMaskIntoConstraints = false
        vibrancyView.contentView.addSubview(button)
        button.pinToParent()
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: HUDButton.height).priority(.defaultHigh),
        ])
    }
}
