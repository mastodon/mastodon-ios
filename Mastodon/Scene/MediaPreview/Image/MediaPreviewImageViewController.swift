//
//  MediaPreviewImageViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import FLAnimatedImage
import VisionKit

protocol MediaPreviewImageViewControllerDelegate: AnyObject {
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, tapGestureRecognizerDidTrigger tapGestureRecognizer: UITapGestureRecognizer)
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, contextMenuActionPerform action: MediaPreviewImageViewController.ContextMenuAction)
}

final class MediaPreviewImageViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    var viewModel: MediaPreviewImageViewModel!
    weak var delegate: MediaPreviewImageViewControllerDelegate?

    // let progressBarView = ProgressBarView()
    let previewImageView = MediaPreviewImageView()

    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer

    deinit {
        previewImageView.imageView.af.cancelImageRequest()
    }
}

extension MediaPreviewImageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 16.0, *) {
            previewImageView.liveTextInteraction.delegate = self
        }
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewImageView)
        NSLayoutConstraint.activate([
            previewImageView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            previewImageView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tapGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.tapGestureRecognizerHandler(_:)))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.require(toFail: previewImageView.doubleTapGestureRecognizer)
        previewImageView.addGestureRecognizer(tapGestureRecognizer)

        let previewImageViewContextMenuInteraction = UIContextMenuInteraction(delegate: self)
        previewImageView.addInteraction(previewImageViewContextMenuInteraction)

        previewImageView.imageView.accessibilityLabel = viewModel.item.altText

        if let thumbnail = viewModel.item.thumbnail {
            previewImageView.imageView.image = thumbnail
            previewImageView.setup(image: thumbnail, container: self.previewImageView, forceUpdate: true)
        }

        previewImageView.imageView.setImage(
            url: viewModel.item.assetURL,
            placeholder: viewModel.item.thumbnail,
            scaleToSize: nil
        ) { [weak self] image in
            guard let self = self else { return }
            guard let image = image else { return }
            self.previewImageView.setup(image: image, container: self.previewImageView, forceUpdate: true)
        }
    }
    
}

extension MediaPreviewImageViewController {
    
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        delegate?.mediaPreviewImageViewController(self, tapGestureRecognizerDidTrigger: sender)
    }
    
}

extension MediaPreviewImageViewController: MediaPreviewPage {
    func setShowingChrome(_ showingChrome: Bool) {
        if #available(iOS 16.0, *) {
            UIView.animate(withDuration: 0.3) {
                self.previewImageView.liveTextInteraction.setSupplementaryInterfaceHidden(!showingChrome, animated: true)
            }
        }
    }
}

// MARK: - ImageAnalysisInteractionDelegate
@available(iOS 16.0, *)
extension MediaPreviewImageViewController: ImageAnalysisInteractionDelegate {
    func presentingViewController(for interaction: ImageAnalysisInteraction) -> UIViewController? {
        self
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MediaPreviewImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if #available(iOS 16.0, *) {
            let location = touch.location(in: previewImageView.imageView)
            // for tap gestures, only items that can be tapped are relevant
            if gestureRecognizer is UITapGestureRecognizer {
                return !previewImageView.liveTextInteraction.hasSupplementaryInterface(at: location)
                    && !previewImageView.liveTextInteraction.hasDataDetector(at: location)
            } else {
                // for long press, block out everything
                return !previewImageView.liveTextInteraction.hasInteractiveItem(at: location)
            }
        } else {
            return true
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension MediaPreviewImageViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        if #available(iOS 16.0, *) {
            if previewImageView.liveTextInteraction.hasInteractiveItem(at: previewImageView.imageView.convert(location, from: previewImageView)) {
                return nil
            }
        }

        
        let previewProvider: UIContextMenuContentPreviewProvider = { () -> UIViewController? in
            return nil
        }
        
        let saveAction = UIAction(
            title: L10n.Common.Controls.Actions.savePhoto, image: UIImage(systemName: "square.and.arrow.down")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.mediaPreviewImageViewController(self, contextMenuActionPerform: .savePhoto)
        }

        let copyAction = UIAction(
            title: L10n.Common.Controls.Actions.copyPhoto, image: UIImage(systemName: "doc.on.doc")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.mediaPreviewImageViewController(self, contextMenuActionPerform: .copyPhoto)
        }
        
        let shareAction = UIAction(
            title: L10n.Common.Controls.Actions.share, image: UIImage(systemName: "square.and.arrow.up")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.mediaPreviewImageViewController(self, contextMenuActionPerform: .share)
        }
        
        let actionProvider: UIContextMenuActionProvider = { elements -> UIMenu?  in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
                saveAction,
                copyAction,
                shareAction
            ])
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider, actionProvider: actionProvider)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        // set preview view
        return UITargetedPreview(view: previewImageView.imageView)
    }

}

extension MediaPreviewImageViewController {
    enum ContextMenuAction {
        case savePhoto
        case copyPhoto
        case share
    }
}

// MARK: - MediaPreviewTransitionViewController
extension MediaPreviewImageViewController: MediaPreviewTransitionViewController {
    var mediaPreviewTransitionContext: MediaPreviewTransitionContext? {
        let imageView = previewImageView.imageView
        let _snapshot: UIView? = imageView.snapshotView(afterScreenUpdates: false)
        
        guard let snapshot = _snapshot else {
            return nil
        }
        
        return MediaPreviewTransitionContext(
            transitionView: imageView,
            snapshot: snapshot,
            snapshotTransitioning: snapshot
        )
    }
}
