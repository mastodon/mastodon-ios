//
//  ComposeViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

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

final class ComposeViewController: UIViewController {
    static let minAutoCompleteVisibleHeight: CGFloat = 100
    lazy var publishProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.alpha = 0
        return progressView
    }()
    lazy var editPublishProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.alpha = 0
        return progressView
    }()
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel

    init(viewModel: ComposeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.setUpPublishingIndicator()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setUpPublishingIndicator() {
        for (button, progressView) in [(publishButton, publishProgressView), (saveButton, editPublishProgressView)] {
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.tintColor = .systemIndigo
            progressView.trackTintColor = .systemGray
            button.addSubview(progressView)
            let constraints = [
                progressView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                progressView.topAnchor.constraint(equalTo: button.topAnchor),
                progressView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                progressView.heightAnchor.constraint(greaterThanOrEqualToConstant: 35)
            ]
            NSLayoutConstraint.activate(constraints)
        }
        
        PublisherService.shared.$currentPublishProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
                let progress = Float(progress)
                if progress > 0 {
                    UIView.animate(withDuration: 0.25) {
                        self.publishProgressView.alpha = 1
                        self.editPublishProgressView.alpha = 1
                    }
                    self.publishProgressView.setProgress(progress, animated: true)
                    self.editPublishProgressView.setProgress(progress, animated: true)
                }
            }
            .store(in: &disposeBag)
    }

    lazy var composeContentViewModel: ComposeContentViewModel = {

        let composeContext: ComposeContentViewModel.ComposeContext
        let initialContent: String

        switch viewModel.composeContext {
        case .composeStatus(let quoted):
            composeContext = .composeStatus(quoting: quoted)
            initialContent = viewModel.initialContent
        case .editStatus(let status, let statusSource, let quoting):
            composeContext = .editStatus(status: status, statusSource: statusSource, quoting: quoting)
            initialContent = statusSource.text
        }

        return ComposeContentViewModel(
            authenticationBox: viewModel.authenticationBox,
            composeContext: composeContext,
            destination: viewModel.destination,
            initialContent: initialContent,
            completion: viewModel.postPublishCompletion
        )
    }()
    private(set) lazy var composeContentViewController: ComposeContentViewController = {
        let composeContentViewController = ComposeContentViewController()
        composeContentViewController.viewModel = composeContentViewModel
        return composeContentViewController
    }()
    
    private(set) lazy var cancelBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ComposeViewController.cancelBarButtonItemPressed(_:)))

    private lazy var publishButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 5, right: 16)     // set 28pt height
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitle(L10n.Scene.Compose.composeAction, for: .normal)
        button.addTarget(self, action: #selector(ComposeViewController.publishBarButtonItemPressed(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 5, right: 16)     // set 28pt height
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitle(L10n.Common.Controls.Actions.save, for: .normal)
        button.addTarget(self, action: #selector(ComposeViewController.publishStatusEdit(_:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var saveBarButtonItem: UIBarButtonItem = {
        configurePublishButtonApperance(button: saveButton)
        let shadowBackgroundContainer = ShadowBackgroundContainer()
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        shadowBackgroundContainer.addSubview(saveButton)
        saveButton.pinToParent()
        let barButtonItem = UIBarButtonItem(customView: shadowBackgroundContainer)
        return barButtonItem
    }()

    private(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        configurePublishButtonApperance(button: publishButton)
        let shadowBackgroundContainer = ShadowBackgroundContainer()
        publishButton.translatesAutoresizingMaskIntoConstraints = false
        shadowBackgroundContainer.addSubview(publishButton)
        publishButton.pinToParent()
        let barButtonItem = UIBarButtonItem(customView: shadowBackgroundContainer)
        return barButtonItem
    }()

    private func configurePublishButtonApperance(button: UIButton) {
        button.adjustsImageWhenHighlighted = false
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color), for: .normal)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color.withAlphaComponent(0.5)), for: .highlighted)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Button.disabled.color), for: .disabled)
        button.setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
    }

    
}

extension ComposeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        viewModel.traitCollectionDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.traitCollection.userInterfaceIdiom == .pad else { return }
                self.navigationItem.rightBarButtonItem = self.rightBarButtonItemForCurrentContext
            }
            .store(in: &disposeBag)

        navigationItem.rightBarButtonItem = rightBarButtonItemForCurrentContext

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

        switch viewModel.composeContext {
        case .composeStatus:
            configurePublishButtonApperance(button: publishButton)
        case .editStatus:
            configurePublishButtonApperance(button: saveButton)
        }

        viewModel.traitCollectionDidChangePublisher.send()
    }
    
}

extension ComposeViewController {
  
    private func showDismissConfirmAlertController() {
        let alertController = PortraitAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let discardAction = UIAlertAction(title: L10n.Common.Controls.Actions.discard, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: { self.viewModel.postPublishCompletion?(false) })
        }
        alertController.addAction(discardAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = cancelBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    private var rightBarButtonItemForCurrentContext: UIBarButtonItem {
        switch viewModel.composeContext {
        case .composeStatus:
            return publishBarButtonItem
        case .editStatus:
            return saveBarButtonItem
        }
    }
}

extension ComposeViewController {

    private var mediaAttachmentViewModelsWithoutCaption: [AttachmentViewModel] {
        get {
            composeContentViewModel.attachmentViewModels.filter({ $0.caption.isEmpty })
        }
    }

    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard composeContentViewModel.shouldDismiss else {
            showDismissConfirmAlertController()
            return
        }
        dismiss(animated: true, completion: { self.viewModel.postPublishCompletion?(false) })
    }
    
    @objc private func publishBarButtonItemPressed(_ sender: UIBarButtonItem) {

        do {
            try composeContentViewModel.checkAttachmentPrecondition()
        } catch {
            let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            _ = self.sceneCoordinator?.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
            return
        }
        
        let attachmentsWithoutCaptionCount = mediaAttachmentViewModelsWithoutCaption.count

        if UserDefaults.shared.askBeforePostingWithoutAltText && attachmentsWithoutCaptionCount > 0 {
            let alertController = UIAlertController(
                title: L10n.Common.Alerts.MediaMissingAltText.title,
                message: L10n.Common.Alerts.MediaMissingAltText.message(attachmentsWithoutCaptionCount),
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: L10n.Common.Alerts.MediaMissingAltText.cancel, style: .default, handler: nil)
            alertController.addAction(cancelAction)
            let confirmAction = UIAlertAction(title: L10n.Common.Alerts.MediaMissingAltText.post, style: .default) { [weak self] action in
                self?.enqueuePublishStatus()
            }
            alertController.addAction(confirmAction)
            _ = self.sceneCoordinator?.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
            return
        }
        
        enqueuePublishStatus()
    }
    
    private func enqueuePublishStatus() {
        do {
            let statusPublisher = try composeContentViewModel.statusPublisher()
            cancelBarButtonItem.isEnabled = false
            publishButton.isEnabled = false
            statusPublisher.state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    self?.cancelBarButtonItem.isEnabled = true
                    
                    switch result {
                    case .success:
                        self?.publishProgressView.progress = 100
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            self?.dismiss(animated: true, completion: { self?.viewModel.postPublishCompletion?(true) })
                        }
                    case .failure(let error):
                        UIView.animate(withDuration: 0.25) {
                            self?.publishProgressView.alpha = 0
                        }
                        self?.publishButton.isEnabled = true
                        let alertController = UIAlertController.standardAlert(of: error)
                        self?.present(alertController, animated: true)
                        // HomeTimelineViewController is also listening and will post the alert if this view has been dismissed
                    case .pending:
                        break
                    }
                }
                .store(in: &disposeBag)
            
            PublisherService.shared.enqueue(
                statusPublisher: statusPublisher,
                authenticationBox: viewModel.authenticationBox
            )
        } catch {
            let alertController = UIAlertController.standardAlert(of: error)
            present(alertController, animated: true)
            return
        }
    }

    @objc
    private func publishStatusEdit(_ sender: Any) {
        do {
            try composeContentViewModel.checkAttachmentPrecondition()
        } catch {
            let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            _ = self.sceneCoordinator?.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
            return
        }

        let attachmentsWithoutCaptionCount = mediaAttachmentViewModelsWithoutCaption.count

        if UserDefaults.shared.askBeforePostingWithoutAltText && attachmentsWithoutCaptionCount > 0 {
            let alertController = UIAlertController(
                title: L10n.Common.Alerts.MediaMissingAltText.title,
                message: L10n.Common.Alerts.MediaMissingAltText.message(attachmentsWithoutCaptionCount),
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: L10n.Common.Alerts.MediaMissingAltText.cancel, style: .default, handler: nil)
            alertController.addAction(cancelAction)
            let confirmAction = UIAlertAction(title: L10n.Common.Alerts.MediaMissingAltText.post, style: .default) { [weak self] action in
                self?.enqueuePublishStatusEdit()
            }
            alertController.addAction(confirmAction)
            _ = self.sceneCoordinator?.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
            return
        }
        
        enqueuePublishStatusEdit()
    }
    
    private func enqueuePublishStatusEdit() {
        do {
            guard let editStatusPublisher = try composeContentViewModel.statusEditPublisher() else { return }
            cancelBarButtonItem.isEnabled = false
            saveButton.isEnabled = false
            editStatusPublisher.state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    self?.cancelBarButtonItem.isEnabled = true
                    
                    switch result {
                    case .success:
                        self?.editPublishProgressView.progress = 100
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            self?.dismiss(animated: true, completion: { self?.viewModel.postPublishCompletion?(true) })
                        }
                    case .failure(let error):
                        UIView.animate(withDuration: 0.25) {
                            self?.editPublishProgressView.alpha = 0
                        }
                        self?.saveButton.isEnabled = true
                        let alertController = UIAlertController.standardAlert(of: error)
                        self?.present(alertController, animated: true)
                        // HomeTimelineViewController is also listening and will post the alert if this view has been dismissed
                    case .pending:
                        break
                    }
                }
                .store(in: &disposeBag)
            PublisherService.shared.enqueue(
                statusPublisher: editStatusPublisher,
                authenticationBox: viewModel.authenticationBox
            )
        } catch {
            let alertController = UIAlertController.standardAlert(of: error)
            present(alertController, animated: true)
            return
        }
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

        // Look for images on the clipboard
        if UIPasteboard.general.hasImages, let images = UIPasteboard.general.images {
            let attachmentViewModels = images.map { image in
                return AttachmentViewModel(
                    authenticationBox: viewModel.authenticationBox,
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
        showDismissConfirmAlertController()
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
            guard composeContentViewController.documentPickerController.presentingViewController == nil else { return }
            present(composeContentViewController.documentPickerController, animated: true, completion: nil)
        case .mediaPhotoLibrary:
            composeContentViewController.presentPhotoLibraryPicker()
        case .mediaCamera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                return
            }
            guard composeContentViewController.imagePickerController.presentingViewController == nil else { return }
            present(composeContentViewController.imagePickerController, animated: true, completion: nil)
        case .togglePoll:
            composeContentViewModel.isPollActive.toggle()
        case .toggleContentWarning:
            composeContentViewModel.isContentWarningActive.toggle()
        case .selectVisibilityPublic:
            composeContentViewModel.interactionSettingsModel.setInteractionSettings(visibility: .public, quotability: nil)
        // case .selectVisibilityUnlisted:
        //     viewModel.selectedStatusVisibility.value = .unlisted
        case .selectVisibilityPrivate:
            composeContentViewModel.interactionSettingsModel.setInteractionSettings(visibility: .private, quotability: nil)
        case .selectVisibilityDirect:
            composeContentViewModel.interactionSettingsModel.setInteractionSettings(visibility: .direct, quotability: nil)
        }
    }
    
}
