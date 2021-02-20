//
//  MastodonRegisterViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Combine
import MastodonSDK
import os.log
import UIKit
import UITextField_Shake

final class MastodonRegisterViewController: UIViewController, NeedsDependency {
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonRegisterViewModel!

    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    let stackViewTopDistance: CGFloat = 16

    var keyboardFrame: CGRect!
    
    var scrollview: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.showsVerticalScrollIndicator = false
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        return scrollview
    }()
    
    let largeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textColor = Asset.Colors.Label.black.color
        label.text = "Tell us about you."
        return label
    }()
    
    let photoView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    let photoButton: UIButton = {
        let button = UIButton(type: .custom)
        let boldFont = UIFont.systemFont(ofSize: 42)
        let configuration = UIImage.SymbolConfiguration(font: boldFont)
        let image = UIImage(systemName: "person.fill.viewfinder", withConfiguration: configuration)

        button.setImage(image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: UIControl.State.normal)
        button.imageView?.tintColor = Asset.Colors.Icon.photo.color
        button.backgroundColor = .white
        button.layer.cornerRadius = 45
        button.clipsToBounds = true
        return button
    }()
    
    let plusIcon: UIImageView = {
        let icon = UIImageView()
        let boldFont = UIFont.systemFont(ofSize: 24)
        let configuration = UIImage.SymbolConfiguration(font: boldFont)
        let image = UIImage(systemName: "plus.circle.fill", withConfiguration: configuration)
        icon.image = image
        icon.tintColor = Asset.Colors.Icon.plus.color
        return icon
    }()
    
    let domainLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = Asset.Colors.Label.black.color
        return label
    }()
    
    let usernameTextField: UITextField = {
        let textField = UITextField()
        
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.attributedPlaceholder = NSAttributedString(string: "username",
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.lightSecondaryText.color,
                                                                          NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)])
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    let usernameIsTakenLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let displayNameTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.attributedPlaceholder = NSAttributedString(string: "display name",
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.lightSecondaryText.color,
                                                                          NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)])
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.attributedPlaceholder = NSAttributedString(string: "email",
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.lightSecondaryText.color,
                                                                          NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)])
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    let passwordCheckLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 4
        return label
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .asciiCapable
        textField.isSecureTextEntry = true
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.attributedPlaceholder = NSAttributedString(string: "password",
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.lightSecondaryText.color,
                                                                          NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)])
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.lightBrandBlue.color), for: .normal)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.lightDisabled.color), for: .disabled)
        button.isEnabled = false
        button.setTitleColor(Asset.Colors.Label.primary.color, for: .normal)
        button.setTitle("Continue", for: .normal)
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
        
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = Asset.Colors.Background.signUpSystemBackground.color
        domainLabel.text = "@" + viewModel.domain + "  "
        domainLabel.sizeToFit()
        passwordCheckLabel.attributedText = viewModel.attributeStringForPassword()
        usernameTextField.rightView = domainLabel
        usernameTextField.rightViewMode = .always
        usernameTextField.delegate = self
        displayNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // gesture
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: #selector(_resignFirstResponder))
        
        // stackview
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 40
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(largeTitleLabel)
        stackView.addArrangedSubview(photoView)
        stackView.addArrangedSubview(usernameTextField)
        stackView.addArrangedSubview(displayNameTextField)
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(passwordCheckLabel)
        
        // scrollview
        view.addSubview(scrollview)
        NSLayoutConstraint.activate([
            scrollview.frameLayoutGuide.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            scrollview.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: scrollview.frameLayoutGuide.trailingAnchor, constant: 20),
            scrollview.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])
        
        // stackview
        scrollview.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let bottomEdgeLayoutConstraint: NSLayoutConstraint = scrollview.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollview.contentLayoutGuide.topAnchor, constant: stackViewTopDistance),
            stackView.leadingAnchor.constraint(equalTo: scrollview.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollview.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollview.frameLayoutGuide.widthAnchor),
            bottomEdgeLayoutConstraint,
        ])

        // photoview
        photoView.translatesAutoresizingMaskIntoConstraints = false
        photoView.addSubview(photoButton)
        NSLayoutConstraint.activate([
            photoView.heightAnchor.constraint(equalToConstant: 90).priority(.defaultHigh),
        ])
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            photoButton.heightAnchor.constraint(equalToConstant: 90).priority(.defaultHigh),
            photoButton.widthAnchor.constraint(equalToConstant: 90).priority(.defaultHigh),
            photoButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor),
            photoButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor),
        ])
        plusIcon.translatesAutoresizingMaskIntoConstraints = false
        photoView.addSubview(plusIcon)
        NSLayoutConstraint.activate([
            plusIcon.trailingAnchor.constraint(equalTo: photoButton.trailingAnchor),
            plusIcon.bottomAnchor.constraint(equalTo: photoButton.bottomAnchor),
        ])
        
        // textfield
        NSLayoutConstraint.activate([
            usernameTextField.heightAnchor.constraint(equalToConstant: 50).priority(.defaultHigh),
            displayNameTextField.heightAnchor.constraint(equalToConstant: 50).priority(.defaultHigh),
            emailTextField.heightAnchor.constraint(equalToConstant: 50).priority(.defaultHigh),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50).priority(.defaultHigh),
        ])

        // password
        stackView.setCustomSpacing(6, after: passwordTextField)
        stackView.setCustomSpacing(32, after: passwordCheckLabel)
        
        // button
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        
        signUpActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollview.addSubview(signUpActivityIndicatorView)
        NSLayoutConstraint.activate([
            signUpActivityIndicatorView.centerXAnchor.constraint(equalTo: signUpButton.centerXAnchor),
            signUpActivityIndicatorView.centerYAnchor.constraint(equalTo: signUpButton.centerYAnchor),
        ])
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            .sink { [weak self] notification in
                guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return
                }
                self?.keyboardFrame = endFrame
                UIView.animate(withDuration: 0.3) {
                    bottomEdgeLayoutConstraint.constant = UIScreen.main.bounds.height - endFrame.origin.y + 26
                    self?.view.layoutIfNeeded()
                }
            }
            .store(in: &disposeBag)
        
        viewModel.isRegistering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRegistering in
                guard let self = self else { return }
                isRegistering ? self.signUpActivityIndicatorView.startAnimating() : self.signUpActivityIndicatorView.stopAnimating()
                self.signUpButton.setTitle(isRegistering ? "" : "Continue", for: .normal)
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
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: passwordTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let text = self.passwordTextField.text else { return }

                let validations = self.viewModel.validatePassword(text: text)

                self.passwordCheckLabel.attributedText = self.viewModel.attributeStringForPassword(eightCharacters: validations.0, oneNumber: validations.1, oneSpecialCharacter: validations.2)
            }
            .store(in: &disposeBag)
        
        signUpButton.addTarget(self, action: #selector(MastodonRegisterViewController.signUpButtonPressed(_:)), for: .touchUpInside)
    }
}

extension MastodonRegisterViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        var bottomOffsetY: CGFloat = textField.frame.origin.y + textField.frame.height - scrollview.frame.height + keyboardFrame.size.height + stackViewTopDistance
        if textField == passwordTextField {
            bottomOffsetY += passwordCheckLabel.frame.height
        }
        
        if bottomOffsetY > 0 {
            scrollview.setContentOffset(CGPoint(x: 0, y: bottomOffsetY), animated: true)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let valid = validateTextField(textField: textField)
        if valid {
            if validateAllTextField() {
                signUpButton.isEnabled = true
            }
        }
    }

    func showShadowWithColor(color: UIColor, textField: UITextField) {
        // To apply Shadow
        textField.layer.shadowOpacity = 1
        textField.layer.shadowRadius = 2.0
        textField.layer.shadowOffset = CGSize.zero // Use any CGSize
        textField.layer.shadowColor = color.cgColor
    }
    func validateUsername() -> Bool {
        if usernameTextField.text?.count ?? 0 > 0 {
            showShadowWithColor(color: Asset.Colors.TextField.successGreen.color, textField: usernameTextField)
            return true
        } else {
            return false
        }
    }
    func validateDisplayName() -> Bool {
        if displayNameTextField.text?.count ?? 0 > 0 {
            return true
        } else {
            return false
        }
    }
    func validateEmail() -> Bool {
        guard let email = emailTextField.text else {
            return false
        }
        if !viewModel.isValidEmail(email) {
            return false
        }
        return true
    }
    func validatePassword() -> Bool {
        guard let password = passwordTextField.text else {
            return false
        }
        
        let result = viewModel.validatePassword(text: password)
        if !(result.0 && result.1 && result.2) {
            return false
        }
        return true
    }
    func validateTextField(textField: UITextField) -> Bool {
        signUpButton.isEnabled = false
        var isvalid = false
        if textField == usernameTextField {
            isvalid = validateUsername()
        }
        if textField == displayNameTextField {
            isvalid = validateDisplayName()
        }
        if textField == emailTextField {
            isvalid = validateEmail()
        }
        if textField == passwordTextField {
            isvalid = validatePassword()
        }
        if isvalid {
            showShadowWithColor(color: Asset.Colors.TextField.successGreen.color, textField: textField)
        } else {
            textField.shake()
            showShadowWithColor(color: Asset.Colors.lightDangerRed.color, textField: textField)
        }
        return isvalid
    }
    func validateAllTextField() -> Bool {
        return validateUsername() && validateDisplayName() && validateEmail() && validatePassword()
    }
}

extension MastodonRegisterViewController {
    @objc private func _resignFirstResponder() {
        usernameTextField.resignFirstResponder()
        displayNameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    @objc private func signUpButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        if !validateAllTextField() {
            return
        }
        
        guard !viewModel.isRegistering.value else { return }
        viewModel.isRegistering.value = true
        
        let query = Mastodon.API.Account.RegisterQuery(
            reason: nil,
            username: usernameTextField.text!,
            displayname: displayNameTextField.text!,
            email: emailTextField.text!,
            password: passwordTextField.text!,
            agreement: true, // TODO:
            locale: "en" // TODO:
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
            _ = response.value
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
