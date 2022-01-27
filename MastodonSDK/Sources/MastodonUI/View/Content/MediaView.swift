//
//  MediaView.swift
//  MediaView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import AVKit
import UIKit

public final class MediaView: UIView {
    
    public static let cornerRadius: CGFloat = 0
    public static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
    
    public let container = TouchBlockingView()
    
    public private(set) var configuration: Configuration?
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        imageView.layer.masksToBounds = true    // clip overflow
        return imageView
    }()
    
    private(set) lazy var playerViewController: AVPlayerViewController = {
        let playerViewController = AVPlayerViewController()
        playerViewController.view.layer.masksToBounds = true
        playerViewController.view.isUserInteractionEnabled = false
        return playerViewController
    }()
    private var playerLooper: AVPlayerLooper?
    
    private(set) lazy var indicatorBlurEffectView: UIVisualEffectView = {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        effectView.layer.masksToBounds = true
        effectView.layer.cornerCurve = .continuous
        effectView.layer.cornerRadius = 4
        return effectView
    }()
    private(set) lazy var indicatorVibrancyEffectView = UIVisualEffectView(
        effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial))
    )
//    private(set) lazy var playerIndicatorLabel: UILabel = {
//        let label = UILabel()
//        label.font = .preferredFont(forTextStyle: .caption1)
//        label.textColor = .secondaryLabel
//        return label
//    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MediaView {
    
    @MainActor
    public func thumbnail() async -> UIImage? {
        return imageView.image
    }
    
    public func thumbnail() -> UIImage? {
        return imageView.image
    }
    
}

extension MediaView {
    private func _init() {
        // lazy load content later
    }
    
    public func setup(configuration: Configuration) {
        self.configuration = configuration

        setupContainerViewHierarchy()
        
        switch configuration {
        case .image(let info):
            configure(image: info)
        case .gif(let info):
            configure(gif: info)
        case .video(let info):
            configure(video: info)
        }
    }
    
    private func configure(image info: Configuration.ImageInfo) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        let placeholder = UIImage.placeholder(color: .systemGray6)
        guard let urlString = info.assetURL,
              let url = URL(string: urlString) else {
                  imageView.image = placeholder
                  return
              }
        imageView.af.setImage(
            withURL: url,
            placeholderImage: placeholder
        )
    }
    
    private func configure(gif info: Configuration.VideoInfo) {
        // use view controller as View here
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(playerViewController.view)
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: container.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        assert(playerViewController.contentOverlayView != nil)
        if let contentOverlayView = playerViewController.contentOverlayView {
            indicatorBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
            contentOverlayView.addSubview(indicatorBlurEffectView)
            NSLayoutConstraint.activate([
                contentOverlayView.trailingAnchor.constraint(equalTo: indicatorBlurEffectView.trailingAnchor, constant: 11),
                contentOverlayView.bottomAnchor.constraint(equalTo: indicatorBlurEffectView.bottomAnchor, constant: 8),
            ])
            setupIndicatorViewHierarchy()
        }
//        playerIndicatorLabel.attributedText = NSAttributedString(AttributedString("GIF"))
        
        guard let player = setupGIFPlayer(info: info) else { return }
        setupPlayerLooper(player: player)
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        
        // auto play for GIF
        player.play()
    }
    
    private func configure(video info: Configuration.VideoInfo) {
        let imageInfo = Configuration.ImageInfo(
            aspectRadio: info.aspectRadio,
            assetURL: info.previewURL
        )
        configure(image: imageInfo)
        
        indicatorBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(indicatorBlurEffectView)
        NSLayoutConstraint.activate([
            imageView.trailingAnchor.constraint(equalTo: indicatorBlurEffectView.trailingAnchor, constant: 11),
            imageView.bottomAnchor.constraint(equalTo: indicatorBlurEffectView.bottomAnchor, constant: 8),
        ])
        setupIndicatorViewHierarchy()
        
//        playerIndicatorLabel.attributedText = {
//            let imageAttachment = NSTextAttachment(image: UIImage(systemName: "play.fill")!)
//            let imageAttributedString = AttributedString(NSAttributedString(attachment: imageAttachment))
//            let duration: String = {
//                guard let durationMS = info.durationMS else { return "" }
//                let timeInterval = TimeInterval(durationMS / 1000)
//                guard timeInterval > 0 else { return "" }
//                guard let text = MediaView.durationFormatter.string(from: timeInterval) else { return "" }
//                return " \(text)"
//            }()
//            let textAttributedString = AttributedString("\(duration)")
//            var attributedString = imageAttributedString + textAttributedString
//            attributedString.foregroundColor = .secondaryLabel
//            return NSAttributedString(attributedString)
//        }()
        
    }
    
    public func prepareForReuse() {
        // reset appearance
        alpha = 1
        
        // reset image
        imageView.removeFromSuperview()
        imageView.removeConstraints(imageView.constraints)
        imageView.af.cancelImageRequest()
        imageView.image = nil
        
        // reset player
        playerViewController.view.removeFromSuperview()
        playerViewController.contentOverlayView.flatMap { view in
            view.removeConstraints(view.constraints)
        }
        playerViewController.player?.pause()
        playerViewController.player = nil
        playerLooper = nil
        
        // reset indicator
        indicatorBlurEffectView.removeFromSuperview()
        
        // reset container
        container.removeFromSuperview()
        container.removeConstraints(container.constraints)
        
        // reset configuration
        configuration = nil
    }
}

extension MediaView {
    private func setupGIFPlayer(info: Configuration.VideoInfo) -> AVPlayer? {
        guard let urlString = info.assetURL,
              let url = URL(string: urlString)
        else { return nil }
        let playerItem = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: playerItem)
        player.isMuted = true
        return player
    }
    
    private func setupPlayerLooper(player: AVPlayer) {
        guard let queuePlayer = player as? AVQueuePlayer else { return }
        guard let templateItem = queuePlayer.items().first else { return }
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)
    }
    
    private func setupContainerViewHierarchy() {
        guard container.superview == nil else { return }
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupIndicatorViewHierarchy() {
//        let blurEffectView = indicatorBlurEffectView
//        let vibrancyEffectView = indicatorVibrancyEffectView
//        
//        if vibrancyEffectView.superview == nil {
//            vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
//            blurEffectView.contentView.addSubview(vibrancyEffectView)
//            NSLayoutConstraint.activate([
//                vibrancyEffectView.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor),
//                vibrancyEffectView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor),
//                vibrancyEffectView.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor),
//                vibrancyEffectView.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor),
//            ])
//        }
//        
//        if playerIndicatorLabel.superview == nil {
//            playerIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
//            vibrancyEffectView.contentView.addSubview(playerIndicatorLabel)
//            NSLayoutConstraint.activate([
//                playerIndicatorLabel.topAnchor.constraint(equalTo: vibrancyEffectView.contentView.topAnchor),
//                playerIndicatorLabel.leadingAnchor.constraint(equalTo: vibrancyEffectView.contentView.leadingAnchor, constant: 3),
//                vibrancyEffectView.contentView.trailingAnchor.constraint(equalTo: playerIndicatorLabel.trailingAnchor, constant: 3),
//                playerIndicatorLabel.bottomAnchor.constraint(equalTo: vibrancyEffectView.contentView.bottomAnchor),
//            ])
//        }
    }
}
