//
//  ContentWarningOverlayView.swift
//
//
//  Created by MainasuK on 2021-12-14.
//

import os.log
import UIKit

public protocol ContentWarningOverlayViewDelegate: AnyObject {
    func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView)
}

public final class ContentWarningOverlayView: UIView {
    
    public static let blurVisualEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    
    let logger = Logger(subsystem: "ContentWarningOverlayView", category: "View")
    
    public weak var delegate: ContentWarningOverlayViewDelegate?
    
    public let blurVisualEffectView = UIVisualEffectView(effect: ContentWarningOverlayView.blurVisualEffect)
    public let vibrancyVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: ContentWarningOverlayView.blurVisualEffect))
//    let alertImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = Asset.Indices.exclamationmarkTriangleLarge.image.withRenderingMode(.alwaysTemplate)
//        return imageView
//    }()
    
    public let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
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
        // overlay
        blurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurVisualEffectView)
        NSLayoutConstraint.activate([
            blurVisualEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurVisualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurVisualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurVisualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        vibrancyVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurVisualEffectView.contentView.addSubview(vibrancyVisualEffectView)
        NSLayoutConstraint.activate([
            vibrancyVisualEffectView.topAnchor.constraint(equalTo: blurVisualEffectView.contentView.topAnchor),
            vibrancyVisualEffectView.leadingAnchor.constraint(equalTo: blurVisualEffectView.contentView.leadingAnchor),
            vibrancyVisualEffectView.trailingAnchor.constraint(equalTo: blurVisualEffectView.contentView.trailingAnchor),
            vibrancyVisualEffectView.bottomAnchor.constraint(equalTo: blurVisualEffectView.contentView.bottomAnchor),
        ])
        
//        alertImageView.translatesAutoresizingMaskIntoConstraints = false
//        vibrancyVisualEffectView.contentView.addSubview(alertImageView)
//        NSLayoutConstraint.activate([
//            alertImageView.centerXAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.centerXAnchor),
//            alertImageView.centerYAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.centerYAnchor),
//        ])
        
        tapGestureRecognizer.addTarget(self, action: #selector(ContentWarningOverlayView.tapGestureRecognizerHandler(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
}

extension ContentWarningOverlayView {
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.contentWarningOverlayViewDidPressed(self)
    }
}
