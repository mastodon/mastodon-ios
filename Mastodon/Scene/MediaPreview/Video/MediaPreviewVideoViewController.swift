//
//  MediaPreviewVideoViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-9.
//

import UIKit
import AVKit
import Combine
import func AVFoundation.AVMakeRect

final class MediaPreviewVideoViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewVideoViewModel!
    
    let playerViewController = AVPlayerViewController()
    let previewImageView = UIImageView()
    
    private let containerView = UIView()
    
    deinit {
        viewModel.playbackState = .paused
    }
    
}

extension MediaPreviewVideoViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        containerView.pinToParent()
        
        playerViewController.willMove(toParent: self)
        addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(playerViewController.view)
        playerViewController.view.pinToParent()
        playerViewController.didMove(toParent: self)
        
        if let contentOverlayView = playerViewController.contentOverlayView {
            previewImageView.translatesAutoresizingMaskIntoConstraints = false
            contentOverlayView.addSubview(previewImageView)
            previewImageView.pinToParent()
        }
        
        playerViewController.delegate = self
        playerViewController.view.backgroundColor = .clear
        playerViewController.player = viewModel.player
        playerViewController.allowsPictureInPicturePlayback = true
        
        switch viewModel.item {
        case .video:
            break
        case .gif:
            playerViewController.showsPlaybackControls = false
            
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerHandler(_:)))
            pinchGesture.delegate = self
            containerView.addGestureRecognizer(pinchGesture)
        }
        
        viewModel.playbackState = .playing
        
        if let previewURL = viewModel.item.previewURL {
            previewImageView.contentMode = .scaleAspectFit
            previewImageView.af.setImage(
                withURL: previewURL,
                placeholderImage: .placeholder(color: .systemFill)
            )
            
            playerViewController.publisher(for: \.isReadyForDisplay)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isReadyForDisplay in
                    guard let self = self else { return }
                    self.previewImageView.isHidden = isReadyForDisplay
                }
                .store(in: &disposeBag)
        }
    }
}

// MARK: - GestureRecognizerHandler
extension MediaPreviewVideoViewController {
    @objc private func pinchGestureRecognizerHandler(_ gesture: UIPinchGestureRecognizer) {
        guard let gestureView = gesture.view,
              gesture.state == .began || gesture.state == .changed
        else { return }
        
        gestureView.transform = gestureView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1.0
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MediaPreviewVideoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - ShareActivityProvider
extension MediaPreviewVideoViewController: MediaPreviewPage {
    func setShowingChrome(_ showingChrome: Bool) {
        // TODO: does this do anything?
    }
}

// MARK: - AVPlayerViewControllerDelegate
extension MediaPreviewVideoViewController: AVPlayerViewControllerDelegate {
    
}

// MARK: - MediaPreviewTransitionViewController
extension MediaPreviewVideoViewController: MediaPreviewTransitionViewController {
    var mediaPreviewTransitionContext: MediaPreviewTransitionContext? {
        guard let playerView = playerViewController.view else { return nil }
        let _currentFrame: UIImage? = {
            guard let player = playerViewController.player else { return nil }
            guard let asset = player.currentItem?.asset else { return nil }
            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImageGenerator.appliesPreferredTrackTransform = true   // fix orientation
            do {
                let cgImage = try assetImageGenerator.copyCGImage(at: player.currentTime(), actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                return image
            } catch {
                return previewImageView.image
            }
        }()
        let _snapshot: UIView? = {
            guard let currentFrame = _currentFrame else { return nil }
            let size = AVMakeRect(aspectRatio: currentFrame.size, insideRect: view.frame).size
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: size))
            imageView.image = currentFrame
            return imageView
        }()
        guard let snapshot = _snapshot else {
            return nil
        }
        
        return MediaPreviewTransitionContext(
            transitionView: playerView,
            snapshot: snapshot,
            snapshotTransitioning: snapshot
        )
    }
}
