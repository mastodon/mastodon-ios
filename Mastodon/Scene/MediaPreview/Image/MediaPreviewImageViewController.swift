//
//  MediaPreviewImageViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import FLAnimatedImage

protocol MediaPreviewImageViewControllerDelegate: AnyObject {
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, tapGestureRecognizerDidTrigger tapGestureRecognizer: UITapGestureRecognizer)
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, longPressGestureRecognizerDidTrigger longPressGestureRecognizer: UILongPressGestureRecognizer)
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
    let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        previewImageView.imageView.af.cancelImageRequest()
    }
}

extension MediaPreviewImageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewImageView)
        NSLayoutConstraint.activate([
            previewImageView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            previewImageView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tapGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.tapGestureRecognizerHandler(_:)))
        longPressGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.longPressGestureRecognizerHandler(_:)))
        tapGestureRecognizer.require(toFail: previewImageView.doubleTapGestureRecognizer)
        tapGestureRecognizer.require(toFail: longPressGestureRecognizer)
        previewImageView.addGestureRecognizer(tapGestureRecognizer)
        previewImageView.addGestureRecognizer(longPressGestureRecognizer)
        
        let previewImageViewContextMenuInteraction = UIContextMenuInteraction(delegate: self)
        previewImageView.addInteraction(previewImageViewContextMenuInteraction)

        switch viewModel.item {
        case .remote(let imageContext):
            previewImageView.imageView.accessibilityLabel = imageContext.altText
            
            if let thumbnail = imageContext.thumbnail {
                previewImageView.imageView.image = thumbnail
                previewImageView.setup(image: thumbnail, container: self.previewImageView, forceUpdate: true)
            }
            
            previewImageView.imageView.setImage(
                url: imageContext.assetURL,
                placeholder: imageContext.thumbnail,
                scaleToSize: nil
            ) { [weak self] image in
                guard let self = self else { return }
                guard let image = image else { return }
                self.previewImageView.setup(image: image, container: self.previewImageView, forceUpdate: true)
            }
            
        case .local(let imageContext):
            let image = imageContext.image
            previewImageView.imageView.image = image
            previewImageView.setup(image: image, container: previewImageView, forceUpdate: true)
            
        }
    }
    
}

extension MediaPreviewImageViewController {
    
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaPreviewImageViewController(self, tapGestureRecognizerDidTrigger: sender)
    }
    
    @objc private func longPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaPreviewImageViewController(self, longPressGestureRecognizerDidTrigger: sender)
    }
    
}

// MARK: - UIContextMenuInteractionDelegate
extension MediaPreviewImageViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let previewProvider: UIContextMenuContentPreviewProvider = { () -> UIViewController? in
            return nil
        }
        
        let saveAction = UIAction(
            title: L10n.Common.Controls.Actions.savePhoto, image: UIImage(systemName: "square.and.arrow.down")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
        ) { [weak self] _ in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save photo", ((#file as NSString).lastPathComponent), #line, #function)
            guard let self = self else { return }
            self.delegate?.mediaPreviewImageViewController(self, contextMenuActionPerform: .savePhoto)
        }

        let copyAction = UIAction(
            title: L10n.Common.Controls.Actions.copyPhoto, image: UIImage(systemName: "doc.on.doc")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
        ) { [weak self] _ in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: copy photo", ((#file as NSString).lastPathComponent), #line, #function)
            guard let self = self else { return }
            self.delegate?.mediaPreviewImageViewController(self, contextMenuActionPerform: .copyPhoto)
        }
        
        let shareAction = UIAction(
            title: L10n.Common.Controls.Actions.share, image: UIImage(systemName: "square.and.arrow.up")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
        ) { [weak self] _ in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: share", ((#file as NSString).lastPathComponent), #line, #function)
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
