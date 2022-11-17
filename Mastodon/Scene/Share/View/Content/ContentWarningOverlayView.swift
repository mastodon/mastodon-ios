//
//  ContentWarningOverlayView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/11.
//

import os.log
import Foundation
import Combine
import UIKit
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI

protocol ContentWarningOverlayViewDelegate: AnyObject {
    func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView)
}

class ContentWarningOverlayView: UIView {

    var disposeBag = Set<AnyCancellable>()
    private var _disposeBag = Set<AnyCancellable>()
    
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
        label.isAccessibilityElement = false
        return label
    }()

    // for status style overlay
    let contentOverlayView: UIView = {
        let view = UIView()
        view.applyCornerRadius(radius: ContentWarningOverlayView.cornerRadius)
        return view
    }()
    let blurContentWarningTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: 23)
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        label.textColor = Asset.Colors.Label.primary.color
        label.textAlignment = .center
        label.isAccessibilityElement = false
        label.numberOfLines = 2
        return label
    }()
    let blurContentWarningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15), maximumPointSize: 20)
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        label.textColor = Asset.Colors.Label.secondary.color
        label.textAlignment = .center
        label.isAccessibilityElement = false
        label.numberOfLines = 2
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
        vibrancyVisualEffectView.pinTo(to: blurVisualEffectView)

        vibrancyContentWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        vibrancyVisualEffectView.contentView.addSubview(vibrancyContentWarningLabel)
        NSLayoutConstraint.activate([
            vibrancyContentWarningLabel.leadingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.leadingAnchor),
            vibrancyContentWarningLabel.trailingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.trailingAnchor),
            vibrancyContentWarningLabel.centerYAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.centerYAnchor),
        ])

        blurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurVisualEffectView)
        blurVisualEffectView.pinToParent()

        // blur image style
        contentOverlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentOverlayView)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: contentOverlayView.topAnchor),
            leadingAnchor.constraint(equalTo: contentOverlayView.leadingAnchor),
            contentOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        let blurContentWarningLabelContainer = UIStackView()
        blurContentWarningLabelContainer.axis = .vertical
        blurContentWarningLabelContainer.spacing = 4
        blurContentWarningLabelContainer.alignment = .center
        
        blurContentWarningLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        contentOverlayView.addSubview(blurContentWarningLabelContainer)
        blurContentWarningLabelContainer.pinTo(to: self)

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
        blurContentWarningTitleLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)
        blurContentWarningLabel.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
    
        tapGestureRecognizer.addTarget(self, action: #selector(ContentWarningOverlayView.tapGestureRecognizerHandler(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        
        configure(style: .media)
        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &_disposeBag)
    }

    private func setupBackgroundColor(theme: Theme) {
        contentOverlayView.backgroundColor = theme.contentWarningOverlayBackgroundColor
    }
}

extension ContentWarningOverlayView {
    
    enum Style {
        case media              // visualEffectView for media
        case contentWarning     // overlay for post
    }
    
    func configure(style: Style) {
        switch style {
        case .media:
            blurVisualEffectView.isHidden = false
            vibrancyVisualEffectView.isHidden = false
            contentOverlayView.isHidden = true
        case .contentWarning:
            blurVisualEffectView.isHidden = true
            vibrancyVisualEffectView.isHidden = true
            contentOverlayView.isHidden = false
        }
    }
    
    func update(isRevealing: Bool, style: Style) {
        switch style {
        case .media:
            blurVisualEffectView.effect = isRevealing ? nil : ContentWarningOverlayView.blurVisualEffect
            vibrancyVisualEffectView.alpha = isRevealing ? 0 : 1
            isUserInteractionEnabled = !isRevealing
        case .contentWarning:
            assertionFailure("not handle here")
            break
        }
    }
    
    func update(cornerRadius: CGFloat) {
        blurVisualEffectView.layer.cornerRadius = cornerRadius
    }
    
}

extension ContentWarningOverlayView {
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.contentWarningOverlayViewDidPressed(self)
    }
}
