//
//  MosaicView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/11.
//

import Foundation
import UIKit

class MosaicView: UIView {
    static let cornerRadius: CGFloat = 4
    static let blurVisualEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    let blurVisualEffectView = UIVisualEffectView(effect: MosaicView.blurVisualEffect)
    let vibrancyVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: MosaicView.blurVisualEffect))

    let mosaicButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let contentWarningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension MosaicView {
    private func _init() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        // add blur visual effect view in the setup method
        blurVisualEffectView.layer.masksToBounds = true
        blurVisualEffectView.layer.cornerRadius = MosaicView.cornerRadius
        blurVisualEffectView.layer.cornerCurve = .continuous

        vibrancyVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurVisualEffectView.contentView.addSubview(vibrancyVisualEffectView)
        NSLayoutConstraint.activate([
            vibrancyVisualEffectView.topAnchor.constraint(equalTo: blurVisualEffectView.topAnchor),
            vibrancyVisualEffectView.leadingAnchor.constraint(equalTo: blurVisualEffectView.leadingAnchor),
            vibrancyVisualEffectView.trailingAnchor.constraint(equalTo: blurVisualEffectView.trailingAnchor),
            vibrancyVisualEffectView.bottomAnchor.constraint(equalTo: blurVisualEffectView.bottomAnchor),
        ])

        contentWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        vibrancyVisualEffectView.contentView.addSubview(contentWarningLabel)
        NSLayoutConstraint.activate([
            contentWarningLabel.leadingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.leadingAnchor),
            contentWarningLabel.trailingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.trailingAnchor),
            contentWarningLabel.centerYAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.centerYAnchor),
        ])
        
        blurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurVisualEffectView)
        NSLayoutConstraint.activate([
            blurVisualEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurVisualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurVisualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurVisualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        addSubview(mosaicButton)
        NSLayoutConstraint.activate([
            mosaicButton.topAnchor.constraint(equalTo: topAnchor),
            mosaicButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            mosaicButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            mosaicButton.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }
}
