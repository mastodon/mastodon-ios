//
//  MediaView.swift
//  MediaView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import AVKit
import UIKit
import Combine
import AlamofireImage
import SwiftUI
import MastodonLocalization
import MastodonAsset

public final class MediaView: UIView {
    
    var _disposeBag = Set<AnyCancellable>()
    
    public static let cornerRadius: CGFloat = 0
    public static let placeholderImage = UIImage.placeholder(color: .systemGray6)
    
    public let container = TouchBlockingView()
    
    public private(set) var configuration: Configuration?
    
    private(set) lazy var blurhashImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        imageView.layer.masksToBounds = true    // clip overflow
        imageView.backgroundColor = .gray
        imageView.isOpaque = true
        return imageView
    }()
    
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
        playerViewController.videoGravity = .resizeAspectFill
        playerViewController.updatesNowPlayingInfoCenter = false
        return playerViewController
    }()
    private var playerLooper: AVPlayerLooper?

    let overlayViewController: UIHostingController<InlineMediaOverlayContainer> = {
        let vc = UIHostingController(rootView: InlineMediaOverlayContainer())
        vc.view.backgroundColor = .clear
        return vc
    }()

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
        return imageView.image ?? configuration?.previewImage
    }
    
    public func thumbnail() -> UIImage? {
        return imageView.image ?? configuration?.previewImage
    }
    
}

extension MediaView {
    private func _init() {
        // lazy load content later
        
        isAccessibilityElement = true
    }
    
    public func setup(configuration: Configuration) {
        self.configuration = configuration

        setupContainerViewHierarchy()
        
        switch configuration.info {
        case .image(let info):
            layoutImage()
            overlayViewController.rootView.mediaType = .image
            bindImage(configuration: configuration, info: info)
            accessibilityHint = L10n.Common.Controls.Status.Media.expandImageHint
        case .gif(let info):
            layoutGIF()
            overlayViewController.rootView.mediaType = .gif
            bindGIF(configuration: configuration, info: info)
            accessibilityHint = L10n.Common.Controls.Status.Media.expandGifHint
        case .video(let info):
            layoutVideo()
            overlayViewController.rootView.mediaType = .video
            bindVideo(configuration: configuration, info: info)
            accessibilityHint = L10n.Common.Controls.Status.Media.expandVideoHint
        }
        
        accessibilityTraits.insert([.button, .image])

        layoutBlurhash()
        bindBlurhash(configuration: configuration)
    }
    
    private func layoutImage() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        imageView.pinToParent()
        layoutAlt()
    }
    
    private func bindImage(configuration: Configuration, info: Configuration.ImageInfo) {        
        Publishers.CombineLatest3(
            configuration.$isReveal,
            configuration.$previewImage,
            configuration.$blurhashImage
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isReveal, previewImage, blurhashImage in
            guard let self = self else { return }
            
            let image = isReveal ?
                (previewImage ?? blurhashImage ?? MediaView.placeholderImage) :
                (blurhashImage ?? MediaView.placeholderImage)
            self.imageView.image = image
        }
        .store(in: &configuration.disposeBag)

        bindAlt(configuration: configuration, altDescription: info.altDescription)
    }
    
    private func layoutGIF() {
        // use view controller as View here
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(playerViewController.view)
        playerViewController.view.pinToParent()

        layoutAlt()
    }
    
    private func bindGIF(configuration: Configuration, info: Configuration.VideoInfo) {
        overlayViewController.rootView.mediaDuration = info.durationMS.map { Double($0) / 1000 }
        overlayViewController.rootView.showDuration = false

        guard let player = setupGIFPlayer(info: info) else { return }
        setupPlayerLooper(player: player)
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        
        // auto play for GIF
        if !UIAccessibility.isReduceMotionEnabled {
            player.play()
        }
        NotificationCenter.default
            .publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { _ in
                if UIAccessibility.isReduceMotionEnabled {
                    player.pause()
                } else {
                    player.play()
                }
            }
            .store(in: &_disposeBag)

        bindAlt(configuration: configuration, altDescription: info.altDescription)
    }
    
    private func layoutVideo() {
        layoutImage()
    }
    
    private func bindVideo(configuration: Configuration, info: Configuration.VideoInfo) {
        overlayViewController.rootView.mediaDuration = info.durationMS.map { Double($0) / 1000 }
        overlayViewController.rootView.showDuration = true

        let imageInfo = Configuration.ImageInfo(
            aspectRadio: info.aspectRadio,
            assetURL: info.previewURL,
            altDescription: info.altDescription
        )
        bindImage(configuration: configuration, info: imageInfo)
    }
    
    private func bindAlt(configuration: Configuration, altDescription: String?) {
        if configuration.total > 1 {
            accessibilityLabel = L10n.Common.Controls.Status.Media.accessibilityLabel(
                altDescription ?? "",
                configuration.index + 1,
                configuration.total
            )
        } else {
            accessibilityLabel = altDescription
        }

        overlayViewController.rootView.altDescription = altDescription
    }

    private func layoutBlurhash() {
        blurhashImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blurhashImageView)
        blurhashImageView.pinToParent()
    }
    
    private func bindBlurhash(configuration: Configuration) {
        configuration.$blurhashImage
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: blurhashImageView)
            .store(in: &_disposeBag)
        blurhashImageView.alpha = configuration.isReveal ? 0 : 1
        
        configuration.$isReveal
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReveal in
                guard let self = self else { return }
                let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut)
                animator.addAnimations {
                    self.blurhashImageView.alpha = isReveal ? 0 : 1
                }
                animator.startAnimation()
            }
            .store(in: &_disposeBag)
    }
    
    private func layoutAlt() {
        overlayViewController.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(overlayViewController.view)
        overlayViewController.view.pinToParent()
    }
    
    public func prepareForReuse() {
        _disposeBag.removeAll()
        
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
        
        // blurhash
        blurhashImageView.removeFromSuperview()
        blurhashImageView.removeConstraints(blurhashImageView.constraints)
        blurhashImageView.image = nil

        // reset container
        container.removeFromSuperview()
        container.removeConstraints(container.constraints)
        
        overlayViewController.rootView.altDescription = nil
        overlayViewController.rootView.showDuration = false
        overlayViewController.rootView.mediaDuration = nil

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
        player.preventsDisplaySleepDuringVideoPlayback = false
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
        container.pinToParent()
    }
}
