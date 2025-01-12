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
        imageView.backgroundColor = .gray
        imageView.isOpaque = true
        return imageView
    }()
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private(set) var playerViewController: AVPlayerViewController?
    private var playerLooper: AVPlayerLooper?
    
    private func createPlayerViewController() -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.view.layer.masksToBounds = true
        playerViewController.view.isUserInteractionEnabled = false
        playerViewController.videoGravity = .resizeAspectFill
        playerViewController.updatesNowPlayingInfoCenter = false
        return playerViewController
    }

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

    public override func layoutSubviews() {
        super.layoutSubviews()

        layoutImageUsingFocus(in: blurhashImageView, container: container.bounds)
        layoutImageUsingFocus(in: imageView, container: container.bounds)
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

    public func contentView() -> UIView {
        return imageView
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
        container.addSubview(imageView)
        container.clipsToBounds = true

        layoutAlt()
    }
    
    private func bindImage(configuration: Configuration, info: Configuration.ImageInfo) {
        let subscribedConfigurationIdentifier = ObjectIdentifier(configuration) // this shouldn't be necessary now, but allows a check in debug mode. https://github.com/mastodon/mastodon-ios/issues/1374
        Publishers.CombineLatest(
            configuration.$previewImage,
            configuration.$blurhashImage
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] previewImage, blurhashImage in
            guard let self = self else { return }
            guard let currentConfiguration = self.configuration, ObjectIdentifier(currentConfiguration) == subscribedConfigurationIdentifier else {
                assert(false, "\(self) attempt to load an image that belongs to a configuration no longer associated with this MediaView.")
                return
            }
            let image = configuration.isReveal ?
                (previewImage ?? blurhashImage ?? MediaView.placeholderImage) :
                (blurhashImage ?? MediaView.placeholderImage)
            self.imageView.image = image
            self.setNeedsLayout()
        }
        .store(in: &_disposeBag)

        bindAlt(configuration: configuration, altDescription: info.altDescription)
    }
    
    private func layoutGIF() {
        // use view controller as View here
        if playerViewController == nil {
            playerViewController = createPlayerViewController()
        }
        guard let playerViewController else { return }
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
        
        if playerViewController == nil {
            playerViewController = createPlayerViewController()
        }
        guard let playerViewController else { return }
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        
        // auto play for GIF
        if configuration.isReveal {
            blurhashImageView.alpha = 0
            player.play()
        } else {
            blurhashImageView.alpha = 1
        }

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
            altDescription: info.altDescription,
            focus: nil
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
        container.addSubview(blurhashImageView)
    }
    
    private func bindBlurhash(configuration: Configuration) {
        configuration.$blurhashImage
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: blurhashImageView)
            .store(in: &_disposeBag)
        blurhashImageView.alpha = configuration.isReveal ? 0 : 1
    }
    
    private func layoutAlt() {
        overlayViewController.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(overlayViewController.view)
        overlayViewController.view.pinToParent()
    }
    
    private func layoutImageUsingFocus(in imageView: UIImageView, container: CGRect) {
        guard let configuration, case let .image(image) = configuration.info,
           let focus = image.focus, let image = imageView.image else {
            imageView.frame = container
            return
        }

        let imageAspect = image.size.width / image.size.height
        let containerAspect = container.size.width / container.size.height

        let scaledSize: CGSize = if imageAspect > containerAspect {
            CGSize(
                width: image.size.width * container.size.height / image.size.height,
                height: container.size.height
            )
        } else {
            CGSize(
                width: container.size.width,
                height: image.size.height * container.size.width / image.size.width
            )
        }

        let focusOffset = CGPoint(
            x: max(
                min(0, (container.size.width / 2 - scaledSize.width / 2) * (1 + focus.x)),
                container.size.width - scaledSize.width
            ),
            y: max(
                min(0, (container.size.height / 2 - scaledSize.height / 2) * (1 + focus.y)),
                container.size.height - scaledSize.height
            )
        )

        imageView.frame = CGRect(origin: focusOffset, size: scaledSize)
    }
    
    @MainActor
    public func prepareForReuse() {
        for cancellable in _disposeBag {
            cancellable.cancel()
        }
        _disposeBag.removeAll()
        
        // reset appearance
        alpha = 1
        
        // reset image
        imageView.removeFromSuperview()
        imageView.removeConstraints(imageView.constraints)
        imageView.af.cancelImageRequest()
        imageView.image = nil
        
        // reset player
        playerViewController?.view.removeFromSuperview()
        playerViewController?.contentOverlayView.flatMap { view in
            view.removeConstraints(view.constraints)
        }
        playerViewController?.player?.pause()
        playerViewController?.player = nil
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
