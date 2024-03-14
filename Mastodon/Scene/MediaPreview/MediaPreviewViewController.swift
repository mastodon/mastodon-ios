//
//  MediaPreviewViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit
import Combine
import Pageboy
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class MediaPreviewViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewViewModel!
        
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    let pagingViewController = MediaPreviewPagingViewController()

    let topToolbar: UIStackView = {
        let stackView = TouchTransparentStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let closeButton = HUDButton { button in
        button.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))!, for: .normal)
    }

    let altButton = HUDButton { button in
        button.setTitle("ALT", for: .normal)
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
        visualEffectView.pinTo(to: pagingViewController.view)
        pagingViewController.didMove(toParent: self)

        view.addSubview(topToolbar)
        NSLayoutConstraint.activate([
            topToolbar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 12),
            topToolbar.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])

        topToolbar.addArrangedSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: HUDButton.height).priority(.defaultHigh),
        ])

        topToolbar.addArrangedSubview(altButton)

        viewModel.mediaPreviewImageViewControllerDelegate = self

        pagingViewController.interPageSpacing = 10
        pagingViewController.delegate = self
        pagingViewController.dataSource = viewModel
        
        closeButton.button.addTarget(self, action: #selector(MediaPreviewViewController.closeButtonPressed(_:)), for: .touchUpInside)
        altButton.button.addTarget(self, action: #selector(MediaPreviewViewController.altButtonPressed(_:)), for: .touchUpInside)

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
                    self.topToolbar.isHidden = {
                        guard index < previewContext.attachments.count else { return false }
                        let attachment = previewContext.attachments[index]
                        return attachment.kind == .video || attachment.kind == .audio
                    }()
                default:
                    break
                }
            }
            .store(in: &disposeBag)

        viewModel.$altText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] altText in
                guard let self else { return }
                UIView.animate(withDuration: 0.3) {
                    if altText == nil {
                        self.altButton.alpha = 0
                    } else {
                        self.altButton.alpha = 1
                    }
                }
            }
            .store(in: &disposeBag)

        viewModel.$showingChrome
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] showingChrome in
                UIView.animate(withDuration: 0.3) {
                    self?.setNeedsStatusBarAppearanceUpdate()
                    self?.topToolbar.alpha = showingChrome ? 1 : 0
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

    override var prefersStatusBarHidden: Bool {
        !viewModel.showingChrome
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

}

extension MediaPreviewViewController {

    @objc private func closeButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func altButtonPressed(_ sender: UIButton) {
        guard let alt = viewModel.altText else { return }

        present(AltTextViewController(alt: alt, sourceView: sender), animated: true)
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true, completion: nil)
        return true
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
            return dismissible
        }
        
        if let _ = pagingViewController.currentViewController as? MediaPreviewVideoViewController {
            return true
        }

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
        let isContainsTap = viewController.previewImageView.imageView.bounds.contains(location)
        
        if isContainsTap {
            self.viewModel.showingChrome.toggle()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func mediaPreviewImageViewController(
        _ viewController: MediaPreviewImageViewController,
        contextMenuActionPerform action: MediaPreviewImageViewController.ContextMenuAction
    ) {
        switch action {
        case .savePhoto:
            guard let assetURL = viewController.viewModel.item.assetURL else { return }
            context.photoLibraryService.save(imageSource: .url(assetURL))
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
                        _ = self.coordinator.present(
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
            guard let assetURL = viewController.viewModel.item.assetURL else { return }

            context.photoLibraryService.copy(imageSource: .url(assetURL))
                .sink { completion in
                    switch completion {
                    case .failure(_):
                        break
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
                    if let assetURL = viewController.viewModel.item.assetURL {
                        activityItems.append(assetURL)
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
    
    func closeKeyCommand(input: String) -> UIKeyCommand {
        UIKeyCommand(
            title: L10n.Scene.Preview.Keyboard.closePreview,
            image: nil,
            action: #selector(MediaPreviewViewController.closePreviewKeyCommandHandler(_:)),
            input: input,
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
            closeKeyCommand(input: UIKeyCommand.inputEscape),
            closeKeyCommand(input: "i"),
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

