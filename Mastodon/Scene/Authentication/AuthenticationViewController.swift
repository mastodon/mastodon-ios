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
    var mastodonPinBasedAuthenticationViewController: UIViewController?
    
    let domainTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "example.com"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .URL
        return textField
    }()
    
    private(set) lazy var signInBarButtonItem = UIBarButtonItem(title: "Sign In", style: .plain, target: self, action: #selector(AuthenticationViewController.signInBarButtonItemPressed(_:)))
    
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
        
        viewModel.isSignInButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: signInBarButtonItem)
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
        viewModel.signInAction.send(domain)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension AuthenticationViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}
