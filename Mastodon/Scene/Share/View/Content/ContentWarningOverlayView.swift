//
//  ContentWarningOverlayView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/11.
//

import os.log
import Foundation
import UIKit

protocol ContentWarningOverlayViewDelegate: class {
    func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView)
}

class ContentWarningOverlayView: UIView {
    
    static let cornerRadius: CGFloat = 4
    static let blurVisualEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    
    let blurVisualEffectView = UIVisualEffectView(effect: ContentWarningOverlayView.blurVisualEffect)
    let vibrancyVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: ContentWarningOverlayView.blurVisualEffect))
    let vibrancyContentWarningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let blurContentImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = false
        return imageView
    }()
    let blurContentWarningTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17))
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        label.textColor = Asset.Colors.Label.primary.color
        label.textAlignment = .center
        return label
    }()
    let blurContentWarningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        label.textColor = Asset.Colors.Label.secondary.color
        label.textAlignment = .center
        label.layer.setupShadow()
        return label
    }()
    
    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    weak var delegate: ContentWarningOverlayViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension ContentWarningOverlayView {
    private func _init() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        // visual effect style
        // add blur visual effect view in the setup method
        blurVisualEffectView.layer.masksToBounds = true
        blurVisualEffectView.layer.cornerRadius = ContentWarningOverlayView.cornerRadius
        blurVisualEffectView.layer.cornerCurve = .continuous

        vibrancyVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurVisualEffectView.contentView.addSubview(vibrancyVisualEffectView)
        NSLayoutConstraint.activate([
            vibrancyVisualEffectView.topAnchor.constraint(equalTo: blurVisualEffectView.topAnchor),
            vibrancyVisualEffectView.leadingAnchor.constraint(equalTo: blurVisualEffectView.leadingAnchor),
            vibrancyVisualEffectView.trailingAnchor.constraint(equalTo: blurVisualEffectView.trailingAnchor),
            vibrancyVisualEffectView.bottomAnchor.constraint(equalTo: blurVisualEffectView.bottomAnchor),
        ])

        vibrancyContentWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        vibrancyVisualEffectView.contentView.addSubview(vibrancyContentWarningLabel)
        NSLayoutConstraint.activate([
            vibrancyContentWarningLabel.leadingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.leadingAnchor),
            vibrancyContentWarningLabel.trailingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.trailingAnchor),
            vibrancyContentWarningLabel.centerYAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.centerYAnchor),
        ])

        blurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurVisualEffectView)
        NSLayoutConstraint.activate([
            blurVisualEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurVisualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurVisualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurVisualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // blur image style
        blurContentImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurContentImageView)
        NSLayoutConstraint.activate([
            blurContentImageView.topAnchor.constraint(equalTo: topAnchor),
            blurContentImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurContentImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurContentImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        let blurContentWarningLabelContainer = UIStackView()
        blurContentWarningLabelContainer.axis = .vertical
        blurContentWarningLabelContainer.spacing = 4
        blurContentWarningLabelContainer.alignment = .center
        
        blurContentWarningLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        blurContentImageView.addSubview(blurContentWarningLabelContainer)
        NSLayoutConstraint.activate([
            blurContentWarningLabelContainer.topAnchor.constraint(equalTo: topAnchor),
            blurContentWarningLabelContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurContentWarningLabelContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurContentWarningLabelContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let topPaddingView = UIView()
        let bottomPaddingView = UIView()
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        blurContentWarningLabelContainer.addArrangedSubview(topPaddingView)
        blurContentWarningLabelContainer.addArrangedSubview(blurContentWarningTitleLabel)
        blurContentWarningLabelContainer.addArrangedSubview(blurContentWarningLabel)
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        blurContentWarningLabelContainer.addArrangedSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            topPaddingView.heightAnchor.constraint(equalTo: bottomPaddingView.heightAnchor, multiplier: 1.0).priority(.defaultHigh),
        ])
        blurContentWarningTitleLabel.setContentHuggingPriority(.defaultHigh + 2, for: .vertical)
        blurContentWarningLabel.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
    
        tapGestureRecognizer.addTarget(self, action: #selector(ContentWarningOverlayView.tapGestureRecognizerHandler(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        
        configure(style: .visualEffectView)
    }
}

extension ContentWarningOverlayView {
    
    enum Style {
        case visualEffectView
        case blurContentImageView
    }
    
    func configure(style: Style) {
        switch style {
        case .visualEffectView:
            blurVisualEffectView.isHidden = false
            vibrancyVisualEffectView.isHidden = false
            blurContentImageView.isHidden = true
        case .blurContentImageView:
            blurVisualEffectView.isHidden = true
            vibrancyVisualEffectView.isHidden = true
            blurContentImageView.isHidden = false
        }
    }
    
    func update(isRevealing: Bool, style: Style) {
        switch style {
        case .visualEffectView:
            blurVisualEffectView.effect = isRevealing ? nil : ContentWarningOverlayView.blurVisualEffect
            vibrancyVisualEffectView.alpha = isRevealing ? 0 : 1
            isUserInteractionEnabled = !isRevealing
        case .blurContentImageView:
            assertionFailure("not handle here")
            break
        }
    }
    
}

extension ContentWarningOverlayView {
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.contentWarningOverlayViewDidPressed(self)
    }
}
