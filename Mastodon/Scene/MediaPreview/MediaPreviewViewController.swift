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
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewViewModel!
    
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    let pagingViewConttroller = MediaPreviewPagingViewController()

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
        
        viewModel.mediaPreviewImageViewControllerDelegate = self

        pagingViewConttroller.interPageSpacing = 10
        pagingViewConttroller.delegate = self
        pagingViewConttroller.dataSource = viewModel
    }
    
}

// MARK: - MediaPreviewingViewController
extension MediaPreviewViewController: MediaPreviewingViewController {
    
    func isInteractiveDismissable() -> Bool {
        return true
//        if let mediaPreviewImageViewController = pagingViewConttroller.currentViewController as? MediaPreviewImageViewController {
//            let previewImageView = mediaPreviewImageViewController.previewImageView
//            // TODO: allow zooming pan dismiss
//            guard previewImageView.zoomScale == previewImageView.minimumZoomScale else {
//                return false
//            }
//
//            let safeAreaInsets = previewImageView.safeAreaInsets
//            let statusBarFrameHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
//            return previewImageView.contentOffset.y <= -(safeAreaInsets.top - statusBarFrameHeight)
//        }
//
//        return false
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
        
    }
    
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, longPressGestureRecognizerDidTrigger longPressGestureRecognizer: UILongPressGestureRecognizer) {
        // delegate?.mediaPreviewViewController(self, longPressGestureRecognizerTriggered: longPressGestureRecognizer)
    }
    
}
