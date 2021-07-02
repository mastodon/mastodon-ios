//
//  PlayerContainerView.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/10.
//

import os.log
import AVKit
import UIKit
import Combine

protocol PlayerContainerViewDelegate: AnyObject {
    func playerContainerView(_ playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
}

final class PlayerContainerView: UIView {
    static let cornerRadius: CGFloat = ContentWarningOverlayView.cornerRadius

    private let container = UIView()
    private let touchBlockingView = TouchBlockingView()
    private var containerHeightLayoutConstraint: NSLayoutConstraint!
    
    let contentWarningOverlayView: ContentWarningOverlayView = {
        let contentWarningOverlayView = ContentWarningOverlayView()
        contentWarningOverlayView.update(cornerRadius: PlayerContainerView.cornerRadius)
        return contentWarningOverlayView
    }()
    
    let playerViewController = AVPlayerViewController()
    
    let blurhashOverlayImageView = UIImageView()
    let mediaTypeIndicatorView = MediaTypeIndicatorView()
    
    weak var delegate: PlayerContainerViewDelegate?
    
    private var isReadyForDisplayObservation: NSKeyValueObservation?
    let isReadyForDisplay = CurrentValueSubject<Bool, Never>(false)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension PlayerContainerView {
    private func _init() {
        // accessibility
        accessibilityIgnoresInvertColors = true
        
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        containerHeightLayoutConstraint = container.heightAnchor.constraint(equalToConstant: 162).priority(.required - 1)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
            containerHeightLayoutConstraint,
        ])
        
        // will not influence full-screen playback
        playerViewController.view.layer.masksToBounds = true
        playerViewController.view.layer.cornerRadius = PlayerContainerView.cornerRadius
        playerViewController.view.layer.cornerCurve = .continuous
        
        blurhashOverlayImageView.translatesAutoresizingMaskIntoConstraints = false
        playerViewController.contentOverlayView!.addSubview(blurhashOverlayImageView)
        NSLayoutConstraint.activate([
            blurhashOverlayImageView.topAnchor.constraint(equalTo: playerViewController.contentOverlayView!.topAnchor),
            blurhashOverlayImageView.leadingAnchor.constraint(equalTo: playerViewController.contentOverlayView!.leadingAnchor),
            blurhashOverlayImageView.trailingAnchor.constraint(equalTo: playerViewController.contentOverlayView!.trailingAnchor),
            blurhashOverlayImageView.bottomAnchor.constraint(equalTo: playerViewController.contentOverlayView!.bottomAnchor),
        ])
        
        // mediaType
        mediaTypeIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        playerViewController.contentOverlayView!.addSubview(mediaTypeIndicatorView)
        NSLayoutConstraint.activate([
            mediaTypeIndicatorView.bottomAnchor.constraint(equalTo: playerViewController.contentOverlayView!.bottomAnchor),
            mediaTypeIndicatorView.rightAnchor.constraint(equalTo: playerViewController.contentOverlayView!.rightAnchor),
            mediaTypeIndicatorView.heightAnchor.constraint(equalToConstant: MediaTypeIndicatorView.indicatorViewSize.height).priority(.required - 1),
            mediaTypeIndicatorView.widthAnchor.constraint(equalToConstant: MediaTypeIndicatorView.indicatorViewSize.width).priority(.required - 1),
        ])
        
        isReadyForDisplayObservation = playerViewController.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] playerViewController, _ in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: isReadyForDisplay: %s", (#file as NSString).lastPathComponent, #line, #function, playerViewController.isReadyForDisplay.description)
            self.isReadyForDisplay.value = playerViewController.isReadyForDisplay
        }
        
        contentWarningOverlayView.delegate = self
    }
}

// MARK: - ContentWarningOverlayViewDelegate
extension PlayerContainerView: ContentWarningOverlayViewDelegate {
    func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.playerContainerView(self, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
}

extension PlayerContainerView {
    func reset() {
        // note: set playerViewController.player pause() and nil in data source configuration process make reloadData not break playing
        
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
        
        blurhashOverlayImageView.image = nil
        
        container.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
    }
    
    func setupPlayer(aspectRatio: CGSize, maxSize: CGSize, parent: UIViewController?) -> AVPlayerViewController {
        reset()
        
        touchBlockingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(touchBlockingView)
        NSLayoutConstraint.activate([
            touchBlockingView.topAnchor.constraint(equalTo: container.topAnchor),
            touchBlockingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            touchBlockingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        let rect = AVMakeRect(
            aspectRatio: aspectRatio,
            insideRect: CGRect(origin: .zero, size: maxSize)
        ).integral
        
        parent?.addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        touchBlockingView.addSubview(playerViewController.view)
        parent.flatMap { playerViewController.didMove(toParent: $0) }
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: touchBlockingView.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: touchBlockingView.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: touchBlockingView.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: touchBlockingView.bottomAnchor),
            touchBlockingView.widthAnchor.constraint(equalToConstant: rect.width).priority(.required - 1),
        ])
        containerHeightLayoutConstraint.constant = rect.height
        containerHeightLayoutConstraint.isActive = true
        
        playerViewController.view.frame.size = rect.size
        
        contentWarningOverlayView.removeFromSuperview()
        contentWarningOverlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            contentWarningOverlayView.topAnchor.constraint(equalTo: touchBlockingView.topAnchor),
            contentWarningOverlayView.leadingAnchor.constraint(equalTo: touchBlockingView.leadingAnchor),
            contentWarningOverlayView.trailingAnchor.constraint(equalTo: touchBlockingView.trailingAnchor),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: touchBlockingView.bottomAnchor)
        ])
        
        bringSubviewToFront(mediaTypeIndicatorView)
        
        return playerViewController
    }
    
    func setMediaKind(kind: VideoPlayerViewModel.Kind) {
        mediaTypeIndicatorView.setMediaKind(kind: kind)
    }
    
    func setMediaIndicator(isHidden: Bool) {
        mediaTypeIndicatorView.alpha = isHidden ? 0 : 1
    }
    
}
