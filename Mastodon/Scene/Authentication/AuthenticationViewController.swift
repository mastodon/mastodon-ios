//
//  AuthenticationViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import os.log
import UIKit
import Combine
import MastodonSDK

final class AuthenticationViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: AuthenticationViewModel!
    
    let domainTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "example.com"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .URL
        return textField
    }()
    
    private(set) lazy var signInBarButtonItem = UIBarButtonItem(title: "Sign In", style: .plain, target: self, action: #selector(AuthenticationViewController.signInBarButtonItemPressed(_:)))
    let activityIndicatorBarButtonItem = UIBarButtonItem.activityIndicatorBarButtonItem
}

extension AuthenticationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Authentication"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = signInBarButtonItem
        
        domainTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(domainTextField)
        NSLayoutConstraint.activate([
            domainTextField.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 8),
            domainTextField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 8),
            domainTextField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: 8),
            domainTextField.heightAnchor.constraint(equalToConstant: 44),   // FIXME:
        ])
        
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: domainTextField)
            .compactMap { notification in
                guard let textField = notification.object as? UITextField? else { return nil }
                return textField?.text ?? ""
            }
            .assign(to: \.value, on: viewModel.input)
            .store(in: &disposeBag)
        
        viewModel.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticating in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem = isAuthenticating ? self.activityIndicatorBarButtonItem : self.signInBarButtonItem
            }
            .store(in: &disposeBag)
        
        viewModel.authenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] domain, user in
                guard let self = self else { return }
                // reset view hierarchy only if needs
                if self.viewModel.viewHierarchyShouldReset {
                    self.context.authenticationService.activeMastodonUser(domain: domain, userID: user.id)
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .failure(let error):
                                assertionFailure(error.localizedDescription)
                            case .success(let isActived):
                                assert(isActived)
                                self.coordinator.setup()
                            }
                        }
                        .store(in: &self.disposeBag)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            .store(in: &disposeBag)
        
        viewModel.isSignInButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: signInBarButtonItem)
            .store(in: &disposeBag)
        
        viewModel.error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                let alertController = UIAlertController(error, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.coordinator.present(
                    scene: .alertController(alertController: alertController),
                    from: nil,
                    transition: .alertController(animated: true, completion: nil)
                )
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        domainTextField.becomeFirstResponder()
    }
    
}

extension AuthenticationViewController {
 
    @objc private func signInBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let domain = viewModel.domain.value else {
            // TODO: alert error
            return
        }
        guard !viewModel.isAuthenticating.value else { return }
        viewModel.isAuthenticating.value = true
        context.apiService.createApplication(domain: domain)
            .tryMap { response -> AuthenticationViewModel.AuthenticateInfo in
                let application = response.value
                guard let clientID = application.clientID,
                      let clientSecret = application.clientSecret else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                let query = Mastodon.API.OAuth.AuthorizeQuery(clientID: clientID)
                let url = Mastodon.API.OAuth.authorizeURL(domain: domain, query: query)
                return AuthenticationViewModel.AuthenticateInfo(
                    domain: domain,
                    clientID: clientID,
                    clientSecret: clientSecret,
                    url: url
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                // trigger state update
                self.viewModel.isAuthenticating.value = false
                
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign in fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    self.viewModel.error.value = error
                case .finished:
                    break
                }
            } receiveValue: { [weak self] info in
                guard let self = self else { return }
                let mastodonPinBasedAuthenticationViewModel = MastodonPinBasedAuthenticationViewModel(authenticateURL: info.url)
                self.viewModel.authenticate(
                    info: info,
                    pinCodePublisher: mastodonPinBasedAuthenticationViewModel.pinCodePublisher
                )
                self.viewModel.mastodonPinBasedAuthenticationViewController = self.coordinator.present(
                    scene: .mastodonPinBasedAuthentication(viewModel: mastodonPinBasedAuthenticationViewModel),
                    from: nil,
                    transition: .modal(animated: true, completion: nil)
                )
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension AuthenticationViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}
