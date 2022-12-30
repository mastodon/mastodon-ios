//
//  ComposeViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
import UIKit
import Combine
import PhotosUI
import Meta
import MetaTextKit
import MastodonMeta
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization
import MastodonSDK

final class ComposeViewController: UIViewController, NeedsDependency {
    
    static let minAutoCompleteVisibleHeight: CGFloat = 100
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!

    let logger = Logger(subsystem: "ComposeViewController", category: "logic")
    
    lazy var composeContentViewModel: ComposeContentViewModel = {
        return ComposeContentViewModel(
            context: context,
            authContext: viewModel.authContext,
            destination: viewModel.destination,
            initialContent: viewModel.initialContent
        )
    }()
    private(set) lazy var composeContentViewController: ComposeContentViewController = {
        let composeContentViewController = ComposeContentViewController()
        composeContentViewController.viewModel = composeContentViewModel
        return composeContentViewController
    }()
    
    private(set) lazy var cancelBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ComposeViewController.cancelBarButtonItemPressed(_:)))

    let publishButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 5, right: 16)     // set 28pt height
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitle(L10n.Scene.Compose.composeAction, for: .normal)
        return button
    }()
    private(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        configurePublishButtonApperance()
        let shadowBackgroundContainer = ShadowBackgroundContainer()
        publishButton.translatesAutoresizingMaskIntoConstraints = false
        shadowBackgroundContainer.addSubview(publishButton)
        publishButton.pinToParent()
        let barButtonItem = UIBarButtonItem(customView: shadowBackgroundContainer)
        return barButtonItem
    }()
    private func configurePublishButtonApperance() {
        publishButton.adjustsImageWhenHighlighted = false
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color), for: .normal)
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color.withAlphaComponent(0.5)), for: .highlighted)
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Button.disabled.color), for: .disabled)
        publishButton.setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
    }

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ComposeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = publishBarButtonItem
        viewModel.traitCollectionDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.traitCollection.userInterfaceIdiom == .pad else { return }
                let items = [self.publishBarButtonItem]
                self.navigationItem.rightBarButtonItems = items
            }
            .store(in: &disposeBag)
        publishButton.addTarget(self, action: #selector(ComposeViewController.publishBarButtonItemPressed(_:)), for: .touchUpInside)
        
        addChild(composeContentViewController)
        composeContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composeContentViewController.view)
        composeContentViewController.view.pinToParent()
        composeContentViewController.didMove(toParent: self)

        // bind title
        viewModel.$title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                guard let self = self else { return }
                self.title = title
            }
            .store(in: &disposeBag)

        // bind publish bar button state
        composeContentViewModel.$isPublishBarButtonItemEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: publishButton)
            .store(in: &disposeBag)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configurePublishButtonApperance()
        viewModel.traitCollectionDidChangePublisher.send()
    }
    
}

extension ComposeViewController {
  
    private func showDismissConfirmAlertController() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let discardAction = UIAlertAction(title: L10n.Common.Controls.Actions.discard, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(discardAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = cancelBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

}

extension ComposeViewController {

    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        guard composeContentViewModel.shouldDismiss else {
            showDismissConfirmAlertController()
            return
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func publishBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        do {
            try composeContentViewModel.checkAttachmentPrecondition()
        } catch {
            let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            _ = coordinator.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
            return
        }
        
        do {
            let statusPublisher = try composeContentViewModel.statusPublisher()
            // let result = try await statusPublisher.publish(api: context.apiService, authContext: viewModel.authContext)
            // if let reactor = presentingViewController?.topMostNotModal as? StatusPublisherReactor {
            //     statusPublisher.reactor = reactor
            // }
            viewModel.context.publisherService.enqueue(
                statusPublisher: statusPublisher,
                authContext: viewModel.authContext
            )
        } catch {
            let alertController = UIAlertController.standardAlert(of: error)
            present(alertController, animated: true)
            return
        }

        dismiss(animated: true, completion: nil)
    }
    
}

extension ComposeViewController {
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        // Enable pasting images
        if (action == #selector(UIResponderStandardEditActions.paste(_:))) {
            return UIPasteboard.general.hasStrings || UIPasteboard.general.hasImages;
        }

        return super.canPerformAction(action, withSender: sender);
    }
    
    override func paste(_ sender: Any?) {
        logger.debug("Paste event received")

        // Look for images on the clipboard
        if UIPasteboard.general.hasImages, let images = UIPasteboard.general.images {
            logger.warning("Got image paste event, however attachments are not yet re-implemented.");
            let attachmentViewModels = images.map { image in
                return AttachmentViewModel(
                    api: viewModel.context.apiService,
                    authContext: viewModel.authContext,
                    input: .image(image),
                    sizeLimit: composeContentViewModel.sizeLimit,
                    delegate: composeContentViewModel
                )
            }
            composeContentViewModel.attachmentViewModels += attachmentViewModels
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            return .overFullScreen
        default:
            return .pageSheet
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return composeContentViewModel.shouldDismiss
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        showDismissConfirmAlertController()
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ComposeViewController {
    override var keyCommands: [UIKeyCommand]? {
        composeKeyCommands
    }
}

extension ComposeViewController {
    
    enum ComposeKeyCommand: String, CaseIterable {
        case discardPost
        case publishPost
        case mediaBrowse
        case mediaPhotoLibrary
        case mediaCamera
        case togglePoll
        case toggleContentWarning
        case selectVisibilityPublic
        // TODO: remove selectVisibilityUnlisted from codebase
        // case selectVisibilityUnlisted
        case selectVisibilityPrivate
        case selectVisibilityDirect

        var title: String {
            switch self {
            case .discardPost:              return L10n.Scene.Compose.Keyboard.discardPost
            case .publishPost:              return L10n.Scene.Compose.Keyboard.publishPost
            case .mediaBrowse:              return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.browse)
            case .mediaPhotoLibrary:        return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.photoLibrary)
            case .mediaCamera:              return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.camera)
            case .togglePoll:               return L10n.Scene.Compose.Keyboard.togglePoll
            case .toggleContentWarning:     return L10n.Scene.Compose.Keyboard.toggleContentWarning
            case .selectVisibilityPublic:   return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.public)
            // case .selectVisibilityUnlisted: return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.unlisted)
            case .selectVisibilityPrivate:  return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.private)
            case .selectVisibilityDirect:   return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.direct)
            }
        }
        
        // UIKeyCommand input
        var input: String {
            switch self {
            case .discardPost:              return "w"      // + command
            case .publishPost:              return "\r"     // (enter) + command
            case .mediaBrowse:              return "b"      // + option + command
            case .mediaPhotoLibrary:        return "p"      // + option + command
            case .mediaCamera:              return "c"      // + option + command
            case .togglePoll:               return "p"      // + shift + command
            case .toggleContentWarning:     return "c"      // + shift + command
            case .selectVisibilityPublic:   return "1"      // + command
            // case .selectVisibilityUnlisted: return "2"      // + command
            case .selectVisibilityPrivate:  return "2"      // + command
            case .selectVisibilityDirect:   return "3"      // + command
            }
        }
        
        var modifierFlags: UIKeyModifierFlags {
            switch self {
            case .discardPost:              return [.command]
            case .publishPost:              return [.command]
            case .mediaBrowse:              return [.alternate, .command]
            case .mediaPhotoLibrary:        return [.alternate, .command]
            case .mediaCamera:              return [.alternate, .command]
            case .togglePoll:               return [.shift, .command]
            case .toggleContentWarning:     return [.shift, .command]
            case .selectVisibilityPublic:   return [.command]
            // case .selectVisibilityUnlisted: return [.command]
            case .selectVisibilityPrivate:  return [.command]
            case .selectVisibilityDirect:   return [.command]
            }
        }
        
        var propertyList: Any {
            return rawValue
        }
    }
    
    var composeKeyCommands: [UIKeyCommand]? {
        ComposeKeyCommand.allCases.map { command in
            UIKeyCommand(
                title: command.title,
                image: nil,
                action: #selector(Self.composeKeyCommandHandler(_:)),
                input: command.input,
                modifierFlags: command.modifierFlags,
                propertyList: command.propertyList,
                alternates: [],
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            )
        }
    }
    
    @objc private func composeKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let command = ComposeKeyCommand(rawValue: rawValue) else { return }
        
        switch command {
        case .discardPost:
            cancelBarButtonItemPressed(cancelBarButtonItem)
        case .publishPost:
            publishBarButtonItemPressed(publishBarButtonItem)
        case .mediaBrowse:
            guard !isViewControllerIsAlreadyModal(composeContentViewController.documentPickerController) else { return }
            present(composeContentViewController.documentPickerController, animated: true, completion: nil)
        case .mediaPhotoLibrary:
            guard !isViewControllerIsAlreadyModal(composeContentViewController.photoLibraryPicker) else { return }
            present(composeContentViewController.photoLibraryPicker, animated: true, completion: nil)
        case .mediaCamera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                return
            }
            guard !isViewControllerIsAlreadyModal(composeContentViewController.imagePickerController) else { return }
            present(composeContentViewController.imagePickerController, animated: true, completion: nil)
        case .togglePoll:
            composeContentViewModel.isPollActive.toggle()
        case .toggleContentWarning:
            composeContentViewModel.isContentWarningActive.toggle()
        case .selectVisibilityPublic:
            composeContentViewModel.visibility = .public
        // case .selectVisibilityUnlisted:
        //     viewModel.selectedStatusVisibility.value = .unlisted
        case .selectVisibilityPrivate:
            composeContentViewModel.visibility = .private
        case .selectVisibilityDirect:
            composeContentViewModel.visibility = .direct
        }
    }
    
    private func isViewControllerIsAlreadyModal(_ viewController: UIViewController) -> Bool {
        return viewController.presentingViewController != nil
    }
    
}
