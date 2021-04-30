//
//  MediaPreviewViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import os.log
import UIKit
import Combine
import Pageboy

final class MediaPreviewViewController: UIViewController, NeedsDependency {
    
    static let closeButtonSize = CGSize(width: 30, height: 30)
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewViewModel!
        
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    let pagingViewConttroller = MediaPreviewPagingViewController()
    
    let closeButtonBackground: UIVisualEffectView = {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        backgroundView.alpha = 0.9
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = MediaPreviewViewController.closeButtonSize.width * 0.5
        return backgroundView
    }()
    
    let closeButtonBackgroundVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial)))
    
    let closeButton: UIButton = {
        let button = HitTestExpandedButton()
        button.imageView?.tintColor = .label
        button.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))!, for: .normal)
        return button
    }()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MediaPreviewViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark
        
        visualEffectView.frame = view.bounds
        view.addSubview(visualEffectView)
        
        pagingViewConttroller.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pagingViewConttroller)
        visualEffectView.contentView.addSubview(pagingViewConttroller.view)
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: pagingViewConttroller.view.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: pagingViewConttroller.view.bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: pagingViewConttroller.view.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: pagingViewConttroller.view.trailingAnchor),
        ])
        pagingViewConttroller.didMove(toParent: self)
        
        closeButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButtonBackground)
        NSLayoutConstraint.activate([
            closeButtonBackground.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 12),
            closeButtonBackground.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor)
        ])
        closeButtonBackgroundVisualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        closeButtonBackground.contentView.addSubview(closeButtonBackgroundVisualEffectView)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButtonBackgroundVisualEffectView.contentView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: closeButtonBackgroundVisualEffectView.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: closeButtonBackgroundVisualEffectView.leadingAnchor),
            closeButtonBackgroundVisualEffectView.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor),
            closeButtonBackgroundVisualEffectView.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: MediaPreviewViewController.closeButtonSize.height).priority(.defaultHigh),
            closeButton.widthAnchor.constraint(equalToConstant: MediaPreviewViewController.closeButtonSize.width).priority(.defaultHigh),
        ])
        
        viewModel.mediaPreviewImageViewControllerDelegate = self

        pagingViewConttroller.interPageSpacing = 10
        pagingViewConttroller.delegate = self
        pagingViewConttroller.dataSource = viewModel
        
        closeButton.addTarget(self, action: #selector(MediaPreviewViewController.closeButtonPressed(_:)), for: .touchUpInside)
        
        // bind view model
        viewModel.currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self = self else { return }
                switch self.viewModel.pushTransitionItem.source {
                case .mosaic(let mosaicImageViewContainer):
                    UIView.animate(withDuration: 0.3) {
                        mosaicImageViewContainer.setImageViews(alpha: 1)
                        mosaicImageViewContainer.setImageView(alpha: 0, index: index)
                    }
                case .profileAvatar, .profileBanner:
                    break
                }
            }
            .store(in: &disposeBag)
    }
    
}

extension MediaPreviewViewController {
    
    @objc private func closeButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - MediaPreviewingViewController
extension MediaPreviewViewController: MediaPreviewingViewController {
    
    func isInteractiveDismissable() -> Bool {
        if let mediaPreviewImageViewController = pagingViewConttroller.currentViewController as? MediaPreviewImageViewController {
            let previewImageView = mediaPreviewImageViewController.previewImageView
            // TODO: allow zooming pan dismiss
            guard previewImageView.zoomScale == previewImageView.minimumZoomScale else {
                return false
            }

            let safeAreaInsets = previewImageView.safeAreaInsets
            let statusBarFrameHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            let dismissable = previewImageView.contentOffset.y <= -(safeAreaInsets.top - statusBarFrameHeight)
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dismissable %s", ((#file as NSString).lastPathComponent), #line, #function, dismissable ? "true" : "false")
            return dismissable
        }

        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dismissable false", ((#file as NSString).lastPathComponent), #line, #function)
        return false
    }
    
}

// MARK: - PageboyViewControllerDelegate
extension MediaPreviewViewController: PageboyViewControllerDelegate {
    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        willScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        // do nothing
    }
    
    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollTo position: CGPoint,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        // do nothing
    }
    
    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        // update page control
        // pageControl.currentPage = index
        viewModel.currentPage.value = index
    }
    
    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didReloadWith currentViewController: UIViewController,
        currentPageIndex: PageboyViewController.PageIndex
    ) {
        // do nothing
    }

}


// MARK: - MediaPreviewImageViewControllerDelegate
extension MediaPreviewViewController: MediaPreviewImageViewControllerDelegate {
    
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, tapGestureRecognizerDidTrigger tapGestureRecognizer: UITapGestureRecognizer) {
        // do nothing
    }
    
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, longPressGestureRecognizerDidTrigger longPressGestureRecognizer: UILongPressGestureRecognizer) {
        // do nothing
    }
    
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, contextMenuActionPerform action: MediaPreviewImageViewController.ContextMenuAction) {
        switch action {
        case .savePhoto:
            switch viewController.viewModel.item {
            case .status(let meta):
                context.photoLibraryService.saveImage(url: meta.url)
                    .sink { _ in
                        // do nothing
                    } receiveValue: { _ in
                        // do nothing
                    }
                    .store(in: &context.disposeBag)
            case .local(let meta):
                context.photoLibraryService.save(image: meta.image, withNotificationFeedback: true)
            }
        case .share:
            let applicationActivities: [UIActivity] = [
                SafariActivity(sceneCoordinator: self.coordinator)
            ]
            let activityViewController = UIActivityViewController(
                activityItems: viewController.viewModel.item.activityItems,
                applicationActivities: applicationActivities
            )
            activityViewController.popoverPresentationController?.sourceView = viewController.previewImageView.imageView
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
}
