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
    
    var scrollview: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.showsVerticalScrollIndicator = false
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        scrollview.keyboardDismissMode = .interactive
        return scrollview
    }()
    
    let largeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: UIFont.boldSystemFont(ofSize: 34))
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
    
    let plusIconBackground: UIImageView = {
        let icon = UIImageView()
        let boldFont = UIFont.systemFont(ofSize: 24)
        let configuration = UIImage.SymbolConfiguration(font: boldFont)
        let image = UIImage(systemName: "plus.circle", withConfiguration: configuration)
        icon.image = image
        icon.tintColor = .white
        return icon
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
            scrollview.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: scrollview.frameLayoutGuide.trailingAnchor),
            scrollview.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            scrollview.frameLayoutGuide.widthAnchor.constraint(equalTo: scrollview.contentLayoutGuide.widthAnchor),
        ])

        // stackview
        scrollview.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollview.contentLayoutGuide.topAnchor, constant: stackViewTopDistance),
            stackView.leadingAnchor.constraint(equalTo: scrollview.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollview.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollview.frameLayoutGuide.widthAnchor),
            scrollview.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
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
        plusIconBackground.translatesAutoresizingMaskIntoConstraints = false
        photoView.addSubview(plusIconBackground)
        NSLayoutConstraint.activate([
            plusIconBackground.trailingAnchor.constraint(equalTo: photoButton.trailingAnchor),
            plusIconBackground.bottomAnchor.constraint(equalTo: photoButton.bottomAnchor),
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

        Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow.eraseToAnyPublisher(),
            KeyboardResponderService.shared.state.eraseToAnyPublisher(),
            KeyboardResponderService.shared.endFrame.eraseToAnyPublisher()
        )
        .sink(receiveValue: { [weak self] isShow, state, endFrame in
            guard let self = self else { return }
            
            guard isShow, state == .dock else {
                self.scrollview.contentInset.bottom = 0.0
                self.scrollview.verticalScrollIndicatorInsets.bottom = 0.0
                return
            }

            // isShow AND dock state
            let contentFrame = self.view.convert(self.scrollview.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                self.scrollview.contentInset.bottom = 0.0
                self.scrollview.verticalScrollIndicatorInsets.bottom = 0.0
                return
            }

            self.scrollview.contentInset.bottom = padding + 16
            self.scrollview.verticalScrollIndicatorInsets.bottom = padding + 16
        })
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

        viewModel.isUsernameValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.usernameTextField, isValid: isValid)
            }
            .store(in: &disposeBag)
        viewModel.isDisplaynameValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.displayNameTextField, isValid: isValid)
            }
            .store(in: &disposeBag)
        viewModel.isEmailValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.emailTextField, isValid: isValid)
            }
            .store(in: &disposeBag)
        viewModel.isPasswordValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.passwordTextField, isValid: isValid)
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest4(
            viewModel.isUsernameValid,
            viewModel.isDisplaynameValid,
            viewModel.isEmailValid,
            viewModel.isPasswordValid
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isUsernameValid, isDisplaynameValid, isEmailValid, isPasswordValid in
            guard let self = self else { return }
            self.signUpButton.isEnabled = isUsernameValid ?? false && isDisplaynameValid ?? false && isEmailValid ?? false && isPasswordValid ?? false
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
        // align to password label when overlap
        if textField === passwordTextField,
           KeyboardResponderService.shared.isShow.value,
           KeyboardResponderService.shared.state.value == .dock {
            let endFrame = KeyboardResponderService.shared.endFrame.value
            let contentFrame = self.scrollview.convert(self.passwordCheckLabel.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            if padding > 0 {
                let contentOffsetY = scrollview.contentOffset.y
                DispatchQueue.main.async {
                    self.scrollview.setContentOffset(CGPoint(x: 0, y: contentOffsetY + padding + 16.0), animated: true)
                }
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case usernameTextField:
            viewModel.username.value = textField.text
        case displayNameTextField:
            viewModel.displayname.value = textField.text
        case emailTextField:
            viewModel.email.value = textField.text
        case passwordTextField:
            viewModel.password.value = textField.text
        default: break
        }
    }

    func showShadowWithColor(color: UIColor, textField: UITextField) {
        // To apply Shadow
        textField.layer.shadowOpacity = 1
        textField.layer.shadowRadius = 2.0
        textField.layer.shadowOffset = CGSize.zero
        textField.layer.shadowColor = color.cgColor
        textField.layer.shadowPath = UIBezierPath(roundedRect: textField.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 2.0, height: 2.0)).cgPath
    }

    func validateAllTextField() -> Bool {
        return viewModel.isUsernameValid.value ?? false && viewModel.isDisplaynameValid.value ?? false && viewModel.isEmailValid.value ?? false && viewModel.isPasswordValid.value ?? false
    }
    
    private func setTextFieldValidAppearance(_ textField: UITextField, isValid: Bool?) {
        guard let isValid = isValid else {
            showShadowWithColor(color: .clear, textField: textField)
            return
        }
        
        if isValid {
            showShadowWithColor(color: Asset.Colors.TextField.successGreen.color, textField: textField)
        } else {
            textField.shake()
            showShadowWithColor(color: Asset.Colors.lightDangerRed.color, textField: textField)
        }
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
        guard validateAllTextField(),
              let username = viewModel.username.value,
              let email = viewModel.email.value,
              let password = viewModel.password.value else {
            return
        }
        
        guard !viewModel.isRegistering.value else { return }
        viewModel.isRegistering.value = true
        
        let query = Mastodon.API.Account.RegisterQuery(
            reason: nil,
            username: username,
            email: email,
            password: password,
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
