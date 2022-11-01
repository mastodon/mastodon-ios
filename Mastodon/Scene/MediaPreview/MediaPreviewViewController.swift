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
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class MediaPreviewViewController: UIViewController, NeedsDependency {
    
    static let closeButtonSize = CGSize(width: 30, height: 30)
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewViewModel!
        
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    let pagingViewController = MediaPreviewPagingViewController()
    
    let closeButtonBackground: UIVisualEffectView = {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        backgroundView.alpha = 0.9
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = MediaPreviewViewController.closeButtonSize.width * 0.5
        return backgroundView
    }()
    
    let closeButtonBackgroundVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial)))
    
    let closeButton: UIButton = {
        let button = HighlightDimmableButton()
        button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
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
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(visualEffectView)
        
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pagingViewController)
        visualEffectView.contentView.addSubview(pagingViewController.view)
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: pagingViewController.view.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: pagingViewController.view.bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: pagingViewController.view.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: pagingViewController.view.trailingAnchor),
        ])
        pagingViewController.didMove(toParent: self)
        
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

        pagingViewController.interPageSpacing = 10
        pagingViewController.delegate = self
        pagingViewController.dataSource = viewModel
        
        closeButton.addTarget(self, action: #selector(MediaPreviewViewController.closeButtonPressed(_:)), for: .touchUpInside)
        
        // bind view model
        viewModel.$currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self = self else { return }
                switch self.viewModel.transitionItem.source {
                case .attachment:
                    break
                case .attachments(let mediaGridContainerView):
                    UIView.animate(withDuration: 0.3) {
                        mediaGridContainerView.setAlpha(1)
                        mediaGridContainerView.setAlpha(0, index: index)
                    }
                case .profileAvatar, .profileBanner:
                    break
                }
            }
            .store(in: &disposeBag)
        
        viewModel.$currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self = self else { return }
                switch self.viewModel.item {
                case .attachment(let previewContext):
                    let needsHideCloseButton: Bool = {
                        guard index < previewContext.attachments.count else { return false }
                        let attachment = previewContext.attachments[index]
                        return attachment.kind == .video    // not hide buttno for audio
                    }()
                    self.closeButtonBackground.isHidden = needsHideCloseButton
                default:
                    break
                }
            }
            .store(in: &disposeBag)
        
//        viewModel.$isPoping
//            .receive(on: DispatchQueue.main)
//            .removeDuplicates()
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                // statusBar style update with animation
//                self.setNeedsStatusBarAppearanceUpdate()
//                UIView.animate(withDuration: 0.3) {
//                }
//            }
//            .store(in: &disposeBag)
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
    
    func isInteractiveDismissible() -> Bool {
        if let mediaPreviewImageViewController = pagingViewController.currentViewController as? MediaPreviewImageViewController {
            let previewImageView = mediaPreviewImageViewController.previewImageView
            // TODO: allow zooming pan dismiss
            guard previewImageView.zoomScale == previewImageView.minimumZoomScale else {
                return false
            }

            let safeAreaInsets = previewImageView.safeAreaInsets
            let statusBarFrameHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            let dismissible = previewImageView.contentOffset.y <= -(safeAreaInsets.top - statusBarFrameHeight) + 3 // add 3pt tolerance
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dismissible %s", ((#file as NSString).lastPathComponent), #line, #function, dismissible ? "true" : "false")
            return dismissible
        }
        
        if let _ = pagingViewController.currentViewController as? MediaPreviewVideoViewController {
            return true
        }

        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dismissible false", ((#file as NSString).lastPathComponent), #line, #function)
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
        viewModel.currentPage = index
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
        let location = tapGestureRecognizer.location(in: viewController.previewImageView.imageView)
        let isContainsTap = viewController.previewImageView.imageView.frame.contains(location)
        
        guard !isContainsTap else { return }
        dismiss(animated: true, completion: nil)
    }
    
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, longPressGestureRecognizerDidTrigger longPressGestureRecognizer: UILongPressGestureRecognizer) {
        // do nothing
    }
    
    func mediaPreviewImageViewController(
        _ viewController: MediaPreviewImageViewController,
        contextMenuActionPerform action: MediaPreviewImageViewController.ContextMenuAction
    ) {
        switch action {
        case .savePhoto:
            let _savePublisher: AnyPublisher<Void, Error>? = {
                switch viewController.viewModel.item {
                case .remote(let previewContext):
                    guard let assetURL = previewContext.assetURL else { return nil }
                    return context.photoLibraryService.save(imageSource: .url(assetURL))
                case .local(let previewContext):
                    return context.photoLibraryService.save(imageSource: .image(previewContext.image))
                }
            }()
            guard let savePublisher = _savePublisher else {
                return
            }
            savePublisher
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .failure(let error):
                        guard let error = error as? PhotoLibraryService.PhotoLibraryError,
                              case .noPermission = error else { return }
                        let alertController = SettingService.openSettingsAlertController(
                            title: L10n.Common.Alerts.SavePhotoFailure.title,
                            message: L10n.Common.Alerts.SavePhotoFailure.message
                        )
                        self.coordinator.present(
                            scene: .alertController(alertController: alertController),
                            from: self,
                            transition: .alertController(animated: true, completion: nil)
                        )
                    case .finished:
                        break
                    }
                } receiveValue: { _ in
                    // do nothing
                }
                .store(in: &context.disposeBag)
        case .copyPhoto:
            let _copyPublisher: AnyPublisher<Void, Error>? = {
                switch viewController.viewModel.item {
                case .remote(let previewContext):
                    guard let assetURL = previewContext.assetURL else { return nil }
                    return context.photoLibraryService.copy(imageSource: .url(assetURL))
                case .local(let previewContext):
                    return context.photoLibraryService.copy(imageSource: .image(previewContext.image))
                }
            }()
            guard let copyPublisher = _copyPublisher else {
                return
            }

            copyPublisher
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: copy photo fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    case .finished:
                        break
                    }
                } receiveValue: { _ in
                    // do nothing
                }
                .store(in: &context.disposeBag)
        case .share:
            let applicationActivities: [UIActivity] = [
                SafariActivity(sceneCoordinator: self.coordinator)
            ]
            let activityViewController = UIActivityViewController(
                activityItems: {
                    var activityItems: [Any] = []
                    switch viewController.viewModel.item {
                    case .remote(let previewContext):
                        if let assetURL = previewContext.assetURL {
                            activityItems.append(assetURL)
                        }
                    case .local(let previewContext):
                        activityItems.append(previewContext.image)
                    }
                    return activityItems
                }(),
                applicationActivities: applicationActivities
            )
            activityViewController.popoverPresentationController?.sourceView = viewController.previewImageView.imageView
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
}

extension MediaPreviewViewController {
    
    var closeKeyCommand: UIKeyCommand {
        UIKeyCommand(
            title: L10n.Scene.Preview.Keyboard.closePreview,
            image: nil,
            action: #selector(MediaPreviewViewController.closePreviewKeyCommandHandler(_:)),
            input: "i",
            modifierFlags: [],
            propertyList: nil,
            alternates: [],
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        )
    }
    
    var showNextKeyCommand: UIKeyCommand {
        UIKeyCommand(
            title: L10n.Scene.Preview.Keyboard.closePreview,
            image: nil,
            action: #selector(MediaPreviewViewController.showNextKeyCommandHandler(_:)),
            input: "j",
            modifierFlags: [],
            propertyList: nil,
            alternates: [],
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        )
    }
    
    
    var showPreviousKeyCommand: UIKeyCommand {
        UIKeyCommand(
            title: L10n.Scene.Preview.Keyboard.closePreview,
            image: nil,
            action: #selector(MediaPreviewViewController.showPreviousKeyCommandHandler(_:)),
            input: "k",
            modifierFlags: [],
            propertyList: nil,
            alternates: [],
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        )
    }
    
    
    override var keyCommands: [UIKeyCommand] {
        return [
            closeKeyCommand,
            showNextKeyCommand,
            showPreviousKeyCommand,
        ]
    }
    
    @objc private func closePreviewKeyCommandHandler(_ sender: UIKeyCommand) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func showNextKeyCommandHandler(_ sender: UIKeyCommand) {
        pagingViewController.scrollToPage(.next, animated: true, completion: nil)
    }
    
    @objc private func showPreviousKeyCommandHandler(_ sender: UIKeyCommand) {
        pagingViewController.scrollToPage(.previous, animated: true, completion: nil)
    }
}

