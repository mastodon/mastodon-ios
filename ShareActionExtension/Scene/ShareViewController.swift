//
//  ShareViewController.swift
//  ShareActionExtension
//
//  Created by MainasuK on 2022/11/13.
//

import UIKit
import Combine
import CoreDataStack
import MastodonCore
import MastodonUI
import MastodonSDK
import MastodonAsset
import MastodonLocalization
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    let context = AppContext.shared
    private(set) lazy var viewModel = ShareViewModel(context: context)
    
    let publishButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 5, right: 16)     // set 28pt height
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitle(L10n.Scene.Compose.composeAction, for: .normal)
        return button
    }()

    private func configurePublishButtonApperance() {
        publishButton.adjustsImageWhenHighlighted = false
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color), for: .normal)
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color.withAlphaComponent(0.5)), for: .highlighted)
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Button.disabled.color), for: .disabled)
        publishButton.setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
    }
    
    private(set) lazy var cancelBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ShareViewController.cancelBarButtonItemPressed(_:)))
    private(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(customView: publishButton)
        publishButton.addTarget(self, action: #selector(ShareViewController.publishBarButtonItemPressed(_:)), for: .touchUpInside)
        return barButtonItem
    }()
    let activityIndicatorBarButtonItem: UIBarButtonItem = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        let barButtonItem = UIBarButtonItem(customView: indicatorView)
        indicatorView.startAnimating()
        return barButtonItem
    }()
    
    private var composeContentViewModel: ComposeContentViewModel?
    private var composeContentViewController: ComposeContentViewController?
    
    let notSignInLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.text = "No Available Account" // TODO: i18n
        return label
    }()
    

}

extension ShareViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTheme()
        ThemeService.shared.apply()

        view.backgroundColor = .systemBackground
        title = L10n.Scene.Compose.Title.newPost
        
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = publishBarButtonItem
        
        do {
            guard let authenticationBox = try setupAuthContext() else {
                setupHintLabel()
                return
            }
            viewModel.authenticationBox = authenticationBox
            let composeContentViewModel = ComposeContentViewModel(
                authenticationBox: authenticationBox,
                composeContext: .composeStatus(quoting: nil),
                destination: .topLevel,
                initialContent: "",
                completion: nil
            )
            let composeContentViewController = ComposeContentViewController()
            composeContentViewController.viewModel = composeContentViewModel
            addChild(composeContentViewController)
            composeContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(composeContentViewController.view)
            composeContentViewController.view.pinToParent()
            composeContentViewController.didMove(toParent: self)
            
            self.composeContentViewModel = composeContentViewModel
            self.composeContentViewController = composeContentViewController
            
            Task { @MainActor in
                let inputItems = self.extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
                await load(inputItems: inputItems)
            }   // end Task
        } catch {
        }
        
        viewModel.$isPublishing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBusy in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem = isBusy ? self.activityIndicatorBarButtonItem : self.publishBarButtonItem
            }
            .store(in: &disposeBag)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configurePublishButtonApperance()
    }
}

extension ShareViewController {
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        extensionContext?.cancelRequest(withError: NSError(domain: "org.joinmastodon.app.ShareActionExtension", code: -1))
    }

    @objc private func publishBarButtonItemPressed(_ sender: UIBarButtonItem) {
        Task { @MainActor in
            viewModel.isPublishing = true
            do {
                guard let author = viewModel.authenticationBox?.cachedAccount else { throw AppError.badRequest }
                let defaultSettings = PostInteractionSettingsViewModel.InitialSettings.fresh(replyingToVisibility: nil).defaultSettings(forAuthor: author)
                guard let statusPublisher = try composeContentViewModel?.statusPublisher(),
                      let authenticationBox = viewModel.authenticationBox
                else {
                    throw AppError.badRequest
                }
                
                _ = try await statusPublisher.publish(api: APIService.shared, authenticationBox: authenticationBox)
                
                self.publishButton.setTitle(L10n.Common.Controls.Actions.done, for: .normal)
                try await Task.sleep(nanoseconds: 1 * .nanosPerUnit)
                
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)

            } catch {
                let alertController = UIAlertController.standardAlert(of: error)
                present(alertController, animated: true)
                return
            }
            viewModel.isPublishing = false

        }
    }
}

extension ShareViewController {
    private func setupAuthContext() throws -> MastodonAuthenticationBox? {

        return AuthenticationServiceProvider.shared.currentActiveUser.value
    }
    
    private func setupHintLabel() {
        notSignInLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notSignInLabel)
        NSLayoutConstraint.activate([
            notSignInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notSignInLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupTheme() {
        view.backgroundColor = SystemTheme.systemElevatedBackgroundColor

        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithDefaultBackground()
        barAppearance.backgroundColor = SystemTheme.navigationBarBackgroundColor
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
    }

    private func showDismissConfirmAlertController() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)        // can not use alert in extension
        let discardAction = UIAlertAction(title: L10n.Common.Controls.Actions.discard, style: .destructive) { _ in
            self.extensionContext?.cancelRequest(withError: ShareError.userCancelShare)
        }
        alertController.addAction(discardAction)
        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ShareViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return composeContentViewModel?.shouldDismiss ?? true
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showDismissConfirmAlertController()
    }
}

extension ShareViewController {
    
    private func load(inputItems: [NSExtensionItem]) async {
        guard let composeContentViewModel = self.composeContentViewModel,
              let authenticationBox = viewModel.authenticationBox
        else {
            assertionFailure()
            return
        }
        var itemProviders: [NSItemProvider] = []

        for item in inputItems {
            itemProviders.append(contentsOf: item.attachments ?? [])
        }
        
        let _textProvider = itemProviders.first { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.plainText.identifier, fileOptions: [])
        }
        
        let _urlProvider = itemProviders.first { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.url.identifier, fileOptions: [])
        }

        let _movieProvider = itemProviders.first { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.movie.identifier, fileOptions: [])
        }

        let imageProviders = itemProviders.filter { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.image.identifier, fileOptions: [])
        }
        
        async let text = ShareViewController.loadText(textProvider: _textProvider)
        async let url = ShareViewController.loadURL(textProvider: _urlProvider)
        
        let content = await [text, url]
            .compactMap { $0 }
            .joined(separator: " ")
        // passby the viewModel `content` value
        if !content.isEmpty {
            composeContentViewModel.content = content + " "
            composeContentViewModel.contentMetaText?.textView.insertText(content + " ")
        }

        if let movieProvider = _movieProvider {
            let attachmentViewModel = AttachmentViewModel(
                authenticationBox: authenticationBox,
                input: .itemProvider(movieProvider),
                sizeLimit: .init(image: nil, video: nil),
                delegate: composeContentViewModel
            )
            composeContentViewModel.attachmentViewModels.append(attachmentViewModel)
        } else if !imageProviders.isEmpty {
            let attachmentViewModels = imageProviders.map { provider in
                AttachmentViewModel(
                    authenticationBox: authenticationBox,
                    input: .itemProvider(provider),
                    sizeLimit: .init(image: nil, video: nil),
                    delegate: composeContentViewModel
                )
            }
            composeContentViewModel.attachmentViewModels.append(contentsOf: attachmentViewModels)
        }
    }
    
    private static func loadText(textProvider: NSItemProvider?) async -> String? {
        guard let textProvider = textProvider else { return nil }
        do {
            let item = try await textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier)
            guard let text = item as? String else { return nil }
            return text
        } catch {
            return nil
        }
    }
    
    private static func loadURL(textProvider: NSItemProvider?) async -> String? {
        guard let textProvider = textProvider else { return nil }
        do {
            let item = try await textProvider.loadItem(forTypeIdentifier: UTType.url.identifier)
            guard let url = item as? URL else { return nil }
            return url.absoluteString
        } catch {
            return nil
        }
    }

}

extension ShareViewController {
    enum ShareError: Error {
        case `internal`(error: Error)
        case userCancelShare
        case missingAuthentication
    }
}

