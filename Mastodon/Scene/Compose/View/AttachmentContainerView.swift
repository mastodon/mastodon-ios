//
//  AttachmentContainerView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit
import UITextView_Placeholder

final class AttachmentContainerView: UIView {
        
    static let containerViewCornerRadius: CGFloat = 4
    
    var descriptionBackgroundViewFrameObservation: NSKeyValueObservation?
    
    let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let emptyStateView = AttachmentContainerView.EmptyStateView()
    let descriptionBackgroundView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = AttachmentContainerView.containerViewCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 5, right: 8)
        return view
    }()
    let descriptionBackgroundGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.withAlphaComponent(0.69).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        return gradientLayer
    }()
    let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.showsVerticalScrollIndicator = false
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
        textView.placeholder = L10n.Scene.Compose.Attachment.descriptionPhoto
        textView.placeholderColor = Asset.Colors.Label.secondary.color
        return textView
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

extension AttachmentContainerView {
    
    private func _init() {
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewImageView)
        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        descriptionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionBackgroundView)
        NSLayoutConstraint.activate([
            descriptionBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            descriptionBackgroundView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
        ])
        descriptionBackgroundView.layer.addSublayer(descriptionBackgroundGradientLayer)
        descriptionBackgroundViewFrameObservation = descriptionBackgroundView.observe(\.bounds, options: [.initial, .new]) { [weak self] _, _ in
            guard let self = self else { return }
            self.descriptionBackgroundGradientLayer.frame = self.descriptionBackgroundView.bounds
        }
        
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionBackgroundView.addSubview(descriptionTextView)
        NSLayoutConstraint.activate([
            descriptionTextView.leadingAnchor.constraint(equalTo: descriptionBackgroundView.layoutMarginsGuide.leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: descriptionBackgroundView.layoutMarginsGuide.trailingAnchor),
            descriptionBackgroundView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: descriptionTextView.bottomAnchor),
            descriptionTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 36),
        ])
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: previewImageView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: previewImageView.centerYAnchor),
        ])
        
        descriptionBackgroundView.overrideUserInterfaceStyle = .dark
        
        emptyStateView.isHidden = true
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
    }
    
}
