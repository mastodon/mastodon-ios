//
//  HUDButton.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-11-24.
//

import UIKit

public class HUDButton: UIView {

    public static let height: CGFloat = 30

    let background: UIVisualEffectView = {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        backgroundView.alpha = 0.9
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = HUDButton.height * 0.5
        return backgroundView
    }()

    let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial)))

    public let button: UIButton = {
        let button = HighlightDimmableButton()
        button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.contentEdgeInsets = .constant(7)
        button.imageView?.tintColor = .label
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))
        return button
    }()

    public init(configure: (UIButton) -> Void) {
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

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        button.point(inside: button.convert(point, from: self), with: event)
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            return button
        } else {
            return nil
        }
    }
}
