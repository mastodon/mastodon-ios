//
//  ShareViewController.swift
//  ShareActionExtension
//
//  Created by MainasuK on 2022/11/13.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonCore
import MastodonUI
import MastodonAsset
import MastodonLocalization
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    
    let logger = Logger(subsystem: "ShareViewController", category: "ViewController")
    
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
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ShareViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTheme(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.apply(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupTheme(theme: theme)
            }
            .store(in: &disposeBag)
        
        view.backgroundColor = .systemBackground
        title = L10n.Scene.Compose.Title.newPost
        
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = publishBarButtonItem
        
        do {
            guard let authContext = try setupAuthContext() else {
                setupHintLabel()
                return
            }
            viewModel.authContext = authContext
            let composeContentViewModel = ComposeContentViewModel(
                context: context,
                authContext: authContext,
                composeContext: .composeStatus,
                destination: .topLevel,
                initialContent: ""
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
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): error: \(error.localizedDescription)")
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
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        extensionContext?.cancelRequest(withError: NSError(domain: "org.joinmastodon.app.ShareActionExtension", code: -1))
    }

    @objc private func publishBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        
        Task { @MainActor in
            viewModel.isPublishing = true
            do {
                guard let statusPublisher = try composeContentViewModel?.statusPublisher(),
                      let authContext = viewModel.authContext
                else {
                    throw AppError.badRequest
                }
                
                _ = try await statusPublisher.publish(api: context.apiService, authContext: authContext)
                
                self.publishButton.setTitle(L10n.Common.Controls.Actions.done, for: .normal)
                try await Task.sleep(nanoseconds: 1 * .second)
                
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
    private func setupAuthContext() throws -> AuthContext? {
        let request = MastodonAuthentication.activeSortedFetchRequest   // use active order
        let _authentication = try context.managedObjectContext.fetch(request).first
        let _authContext = _authentication.flatMap { AuthContext(authentication: $0) }
        return _authContext
    }
    
    private func setupHintLabel() {
        notSignInLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notSignInLabel)
        NSLayoutConstraint.activate([
            notSignInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notSignInLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupTheme(theme: Theme) {
        view.backgroundColor = theme.systemElevatedBackgroundColor

        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithDefaultBackground()
        barAppearance.backgroundColor = theme.navigationBarBackgroundColor
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
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        showDismissConfirmAlertController()
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ShareViewController {
    
    private struct TypedProvider {
        let provider: NSItemProvider
        let type: ProvidedItemType
        
        init?(_ provider: NSItemProvider) {
            self.provider = provider
            for type in ProvidedItemType.allCases {
                if provider.hasRepresentationConforming(toTypeIdentifier: type.uti.identifier) {
                    self.type = type
                    return
                }
            }
            return nil
        }

        enum ProvidedItemType: CaseIterable {
            // in order of priority
            case movie
            case image
            case url
            case text
            
            var uti: UTType {
                switch self {
                case .movie: return .movie
                case .image: return .image
                case .url: return .url
                case .text: return .plainText
                }
            }
        }
    }
    
    private func load(inputItems: [NSExtensionItem]) async {
        guard let composeContentViewModel = self.composeContentViewModel,
              let authContext = viewModel.authContext
        else {
            assertionFailure()
            return
        }
        
        let itemProviders = inputItems
            .flatMap { $0.attachments ?? [] }
            .compactMap(TypedProvider.init)
        
        async let text: String? = loadItem(from: itemProviders, ofType: .text)
        async let url: URL? = loadItem(from: itemProviders, ofType: .url)
        
        let content = await [
            text ?? inputItems.compactMap(\.attributedContentText).first?.string,
            url?.absoluteString
        ].compactMap { $0 }.joined(separator: " ")
        // passby the viewModel `content` value
        if !content.isEmpty {
            composeContentViewModel.content = content + " "
            composeContentViewModel.contentMetaText?.textView.insertText(content + " ")
        }

        let attachmentViewModels = itemProviders.filter { [.movie, .image].contains($0.type) }.map { provider in
            AttachmentViewModel(
                api: context.apiService,
                authContext: authContext,
                input: .itemProvider(provider.provider),
                sizeLimit: .init(image: nil, video: nil),
                delegate: composeContentViewModel
            )
        }
        composeContentViewModel.attachmentViewModels.append(contentsOf: attachmentViewModels)
    }
    
    private func loadItem<Item>(from providers: [TypedProvider], ofType type: TypedProvider.ProvidedItemType) async -> Item? {
        guard let provider = providers.first(where: { $0.type == type }) else { return nil }
        do {
            let item = try await provider.provider.loadItem(forTypeIdentifier: type.uti.identifier)
            guard let result = item as? Item else { return nil }
            return result
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

extension AppContext {
    static let shared = AppContext()
}
