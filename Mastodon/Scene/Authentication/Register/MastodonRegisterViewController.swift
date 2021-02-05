//
//  MastodonRegisterViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import os.log
import UIKit
import Combine
import MastodonSDK
import UITextField_Shake

final class MastodonRegisterViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonRegisterViewModel!
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Username:"
        return label
    }()
    
    let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Email:"
        return label
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "example@gmail.com"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        return textField
    }()
    
    let passwordLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Password:"
        return label
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .asciiCapable
        textField.isSecureTextEntry = true
        return textField
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Background.secondarySystemBackground.color), for: .normal)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Background.secondarySystemBackground.color.withAlphaComponent(0.8)), for: .disabled)
        button.setTitleColor(Asset.Colors.Label.primary.color, for: .normal)
        button.setTitle("Sign up", for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        return button
    }()
    
    let signUpActivityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.hidesWhenStopped = true
        return activityIndicatorView
    }()
    
}

extension MastodonRegisterViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Sign Up"
        view.backgroundColor = Asset.Colors.Background.systemBackground.color
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 8
        
        stackView.addArrangedSubview(usernameLabel)
        stackView.addArrangedSubview(usernameTextField)
        stackView.addArrangedSubview(emailLabel)
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordLabel)
        stackView.addArrangedSubview(passwordTextField)
        
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        
        signUpActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signUpActivityIndicatorView)
        NSLayoutConstraint.activate([
            signUpActivityIndicatorView.centerXAnchor.constraint(equalTo: signUpButton.centerXAnchor),
            signUpActivityIndicatorView.centerYAnchor.constraint(equalTo: signUpButton.centerYAnchor),
        ])
        
        viewModel.isRegistering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRegistering in
                guard let self = self else { return }
                isRegistering ? self.signUpActivityIndicatorView.startAnimating() : self.signUpActivityIndicatorView.stopAnimating()
                self.signUpButton.setTitle(isRegistering ? "" : "Sign up", for: .normal)
                self.signUpButton.isEnabled = !isRegistering
            }
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
        
        signUpButton.addTarget(self, action: #selector(MastodonRegisterViewController.signUpButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension MastodonRegisterViewController {

    @objc private func signUpButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let username = usernameTextField.text else {
            usernameTextField.shake()
            return
        }
        
        guard let email = emailTextField.text else {
            emailTextField.shake()
            return
        }
        
        guard let password = passwordTextField.text else {
            passwordTextField.shake()
            return
        }
        
        guard !viewModel.isRegistering.value else { return }
        viewModel.isRegistering.value = true
        
        let query = Mastodon.API.Account.RegisterQuery(
            username: username,
            email: email,
            password: password,
            agreement: true,        // TODO:
            locale: "en"            // TODO:
        )
        
        context.apiService.accountRegister(
            domain: viewModel.domain,
            query: query,
            authorization: viewModel.applicationAuthorization
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.viewModel.isRegistering.value = false
            switch completion {
            case .failure(let error):
                self.viewModel.error.send(error)
            case .finished:
                break
            }
        } receiveValue: { [weak self] response in
            guard let self = self else { return }
            let _ = response.value
            // TODO:
            let alertController = UIAlertController(title: "Success", message: "Regsiter request sent. Please check your email.\n(Auto sign in not implement yet.)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
            }
            alertController.addAction(okAction)
            self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
        }
        .store(in: &disposeBag)
        
    }

}
