//
//  MastodonRegisterViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import AlamofireImage
import Combine
import MastodonSDK
import os.log
import PhotosUI
import UIKit
import SwiftUI
import MastodonUI
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class MastodonRegisterViewController: UIViewController, NeedsDependency, OnboardingViewControllerAppearance {
    
    static let avatarImageMaxSizeInPixel = CGSize(width: 400, height: 400)
    
    let logger = Logger(subsystem: "MastodonRegisterViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonRegisterViewModel!
    private(set) lazy var mastodonRegisterView = MastodonRegisterView(viewModel: viewModel)

    // picker
    private(set) lazy var imagePicker: PHPickerViewController = {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        return imagePicker
    }()
    private(set) lazy var imagePickerController: UIImagePickerController = {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        return imagePickerController
    }()
    
    private(set) lazy var documentPickerController: UIDocumentPickerViewController = {
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        documentPickerController.delegate = self
        return documentPickerController
    }()
    
    let navigationActionView: NavigationActionView = {
        let navigationActionView = NavigationActionView()
        navigationActionView.backgroundColor = Asset.Scene.Onboarding.background.color
        return navigationActionView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
    }
    
}

extension MastodonRegisterViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem()
        
        setupOnboardingAppearance()
        viewModel.backgroundColor = view.backgroundColor ?? .clear
        defer {
            setupNavigationBarBackgroundView()
        }
        
        let hostingViewController = UIHostingController(rootView: mastodonRegisterView)
        hostingViewController.view.preservesSuperviewLayoutMargins = true
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        hostingViewController.view.pinToParent()
        
        navigationActionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationActionView)
        defer {
            view.bringSubviewToFront(navigationActionView)
        }
        NSLayoutConstraint.activate([
            navigationActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: navigationActionView.bottomAnchor),
        ])
        
        navigationActionView
            .observe(\.bounds, options: [.initial, .new]) { [weak self] navigationActionView, _ in
                guard let self = self else { return }
                let inset = navigationActionView.frame.height
                self.viewModel.bottomPaddingHeight = inset
            }
            .store(in: &observations)
        
        navigationActionView.backButton.addTarget(self, action: #selector(MastodonRegisterViewController.backButtonPressed(_:)), for: .touchUpInside)
        navigationActionView.nextButton.addTarget(self, action: #selector(MastodonRegisterViewController.nextButtonPressed(_:)), for: .touchUpInside)
        
        viewModel.$isAllValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAllValid in
                guard let self = self else { return }
                self.navigationActionView.nextButton.isEnabled = isAllValid
            }
            .store(in: &disposeBag)

        viewModel.endEditing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.view.endEditing(true)
            }
            .store(in: &disposeBag)

//        // return
//        if viewModel.approvalRequired {
//            reasonTextField.returnKeyType = .done
//        } else {
//            passwordTextField.returnKeyType = .done
//        }
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                guard let error = error as? Mastodon.API.Error else { return }
                let alertController = UIAlertController(for: error, title: "Sign Up Failure", preferredStyle: .alert)
                let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                alertController.addAction(okAction)
                _ = self.coordinator.present(
                    scene: .alertController(alertController: alertController),
                    from: nil,
                    transition: .alertController(animated: true, completion: nil)
                )
            }
            .store(in: &disposeBag)

        viewModel.avatarMediaMenuActionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .photoLibrary:
                    self.present(self.imagePicker, animated: true, completion: nil)
                case .camera:
                    self.present(self.imagePickerController, animated: true, completion: nil)
                case .browse:
                    self.present(self.documentPickerController, animated: true, completion: nil)
                case .delete:
                    self.viewModel.avatarImage = nil
                }
            }
            .store(in: &disposeBag)
        
        viewModel.$isRegistering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRegistering in
                guard let self = self else { return }
                isRegistering ? self.navigationActionView.nextButton.showLoading() : self.navigationActionView.nextButton.stopLoading()
            }
            .store(in: &disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
}

extension MastodonRegisterViewController {
    
    @objc private func backButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func nextButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        guard viewModel.isAllValid else { return }

        guard !viewModel.isRegistering else { return }
        viewModel.isRegistering = true

        let username = viewModel.username
        let email = viewModel.email
        let password = viewModel.password
        let reason = viewModel.reason
        
        let locale: String = {
            guard let url = Bundle.main.url(forResource: "local-codes", withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let localCode = try? JSONDecoder().decode(MastodonLocalCode.self, from: data)
            else {
                assertionFailure()
                return "en"
            }
            let fallbackLanguageCode: String = {
                let code = Locale.current.languageCode ?? "en"
                guard localCode[code] != nil else { return "en" }
                return code
            }()

            // pick device preferred language
            guard let identifier = Locale.preferredLanguages.first else {
                return fallbackLanguageCode
            }
            // prepare languageCode and validate then return fallback if needs
            let local = Locale(identifier: identifier)
            guard let languageCode = local.languageCode,
                  localCode[languageCode] != nil
            else {
                return fallbackLanguageCode
            }
            // prepare extendCode and validate then return fallback if needs
            let extendCodes: [String] = {
                let locales = Locale.preferredLanguages.map { Locale(identifier: $0) }
                return locales.compactMap { locale in
                    guard let languageCode = locale.languageCode,
                          let regionCode = locale.regionCode
                    else { return nil }
                    return languageCode + "-" + regionCode
                }
            }()
            let _firstMatchExtendCode = extendCodes.first { code in
                localCode[code] != nil
            }
            guard let firstMatchExtendCode = _firstMatchExtendCode else {
                return languageCode
            }
            return firstMatchExtendCode

        }()
        let query = Mastodon.API.Account.RegisterQuery(
            reason: reason,
            username: username,
            email: email,
            password: password,
            agreement: true, // user confirmed in the server rules scene
            locale: locale
        )

        var retryCount = 0

        // register without show server rules
        context.apiService.accountRegister(
            domain: viewModel.domain,
            query: query,
            authorization: viewModel.applicationAuthorization
        )
        .tryCatch { [weak self] error -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> in
            guard let self = self else { throw error }
            guard let error = self.viewModel.error as? Mastodon.API.Error,
                  case let .generic(errorEntity) = error.mastodonError,
                  errorEntity.error == "Validation failed: Locale is not included in the list"
            else {
                throw error
            }
            guard retryCount == 0 else {
                throw error
            }
            let retryQuery = Mastodon.API.Account.RegisterQuery(
                reason: query.reason,
                username: query.username,
                email: query.email,
                password: query.password,
                agreement: query.agreement,
                locale: self.viewModel.instance.languages?.first ?? "en"
            )
            retryCount += 1
            return self.context.apiService.accountRegister(
                domain: self.viewModel.domain,
                query: retryQuery,
                authorization: self.viewModel.applicationAuthorization
            )
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.viewModel.isRegistering = false
            switch completion {
            case .failure(let error):
                self.viewModel.error = error
            case .finished:
                break
            }
        } receiveValue: { [weak self] response in
            guard let self = self else { return }
            let userToken = response.value
            let updateCredentialQuery: Mastodon.API.Account.UpdateCredentialQuery = {
                let displayName: String? = self.viewModel.name.isEmpty ? nil : self.viewModel.name
                let avatar: Mastodon.Query.MediaAttachment? = {
                    guard let avatarImage = self.viewModel.avatarImage else { return nil }
                    guard avatarImage.size.width <= MastodonRegisterViewController.avatarImageMaxSizeInPixel.width else {
                        return .png(avatarImage.af.imageScaled(to: MastodonRegisterViewController.avatarImageMaxSizeInPixel).pngData())
                    }
                    return .png(avatarImage.pngData())
                }()
                return Mastodon.API.Account.UpdateCredentialQuery(
                    displayName: displayName,
                    avatar: avatar
                )
            }()
            let viewModel = MastodonConfirmEmailViewModel(context: self.context, email: email, authenticateInfo: self.viewModel.authenticateInfo, userToken: userToken, updateCredentialQuery: updateCredentialQuery)
            _ = self.coordinator.present(scene: .mastodonConfirmEmail(viewModel: viewModel), from: self, transition: .show)
        }
        .store(in: &disposeBag)
    }
    
}
