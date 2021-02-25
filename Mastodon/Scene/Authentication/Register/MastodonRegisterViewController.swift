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

final class MastodonRegisterViewController: UIViewController, NeedsDependency, OnboardingViewControllerAppearance {
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonRegisterViewModel!

    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    let statusBarBackground: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        return view
    }()
    
    let scrollView: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.showsVerticalScrollIndicator = false
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        scrollview.keyboardDismissMode = .interactive
        scrollview.clipsToBounds = false    // make content could display over bleeding
        return scrollview
    }()
    
    let largeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: UIFont.boldSystemFont(ofSize: 34))
        label.textColor = .black
        label.text = L10n.Scene.Register.title
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
        label.textColor = .black
        return label
    }()
    
    let usernameTextField: UITextField = {
        let textField = UITextField()
        
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.Username.placeholder,
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
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.DisplayName.placeholder,
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
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.Email.placeholder,
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
        label.numberOfLines = 0
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
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.Password.placeholder,
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
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
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
        
        self.setupOnboardingAppearance()
        
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
        tapGestureRecognizer.addTarget(self, action: #selector(tapGestureRecognizerHandler))
        
        // stackview
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 40
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 26, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(largeTitleLabel)
        stackView.addArrangedSubview(photoView)
        stackView.addArrangedSubview(usernameTextField)
        stackView.addArrangedSubview(displayNameTextField)
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(passwordCheckLabel)
        
        // scrollView
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),
        ])

        // stackview
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
        
        statusBarBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusBarBackground)
        NSLayoutConstraint.activate([
            statusBarBackground.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBackground.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
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
            signUpButton.heightAnchor.constraint(equalToConstant: 46).priority(.defaultHigh),
        ])

        signUpActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(signUpActivityIndicatorView)
        NSLayoutConstraint.activate([
            signUpActivityIndicatorView.centerXAnchor.constraint(equalTo: signUpButton.centerXAnchor),
            signUpActivityIndicatorView.centerYAnchor.constraint(equalTo: signUpButton.centerYAnchor),
        ])

        Publishers.CombineLatest(
            KeyboardResponderService.shared.state.eraseToAnyPublisher(),
            KeyboardResponderService.shared.willEndFrame.eraseToAnyPublisher()
        )
        .sink(receiveValue: { [weak self] state, endFrame in
            guard let self = self else { return }
            
            guard state == .dock else {
                self.scrollView.contentInset.bottom = 0.0
                self.scrollView.verticalScrollIndicatorInsets.bottom = 0.0
                return
            }

            let contentFrame = self.view.convert(self.scrollView.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                self.scrollView.contentInset.bottom = 0.0
                self.scrollView.verticalScrollIndicatorInsets.bottom = 0.0
                return
            }
            
            self.scrollView.contentInset.bottom = padding + 16
            self.scrollView.verticalScrollIndicatorInsets.bottom = padding + 16
            
            if self.passwordTextField.isFirstResponder {
                let contentFrame = self.scrollView.convert(self.signUpButton.frame, to: nil)
                let labelPadding = contentFrame.maxY - endFrame.minY
                let contentOffsetY = self.scrollView.contentOffset.y
                DispatchQueue.main.async {
                    self.scrollView.setContentOffset(CGPoint(x: 0, y: contentOffsetY + labelPadding + 16.0), animated: true)
                }
            }
        })
        .store(in: &disposeBag)

        viewModel.isRegistering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRegistering in
                guard let self = self else { return }
                isRegistering ? self.signUpActivityIndicatorView.startAnimating() : self.signUpActivityIndicatorView.stopAnimating()
                self.signUpButton.setTitle(isRegistering ? "" : L10n.Common.Controls.Actions.continue, for: .normal)
                self.signUpButton.isEnabled = !isRegistering
            }
            .store(in: &disposeBag)

        viewModel.usernameValidateState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] validateState in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.usernameTextField, validateState: validateState)
            }
            .store(in: &disposeBag)
        viewModel.displayNameValidateState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] validateState in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.displayNameTextField, validateState: validateState)
            }
            .store(in: &disposeBag)
        viewModel.emailValidateState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] validateState in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.emailTextField, validateState: validateState)
            }
            .store(in: &disposeBag)
        viewModel.passwordValidateState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] validateState in
                guard let self = self else { return }
                self.setTextFieldValidAppearance(self.passwordTextField, validateState: validateState)
                self.passwordCheckLabel.attributedText = self.viewModel.attributeStringForPassword(eightCharacters: validateState == .valid)

            }
            .store(in: &disposeBag)
        
        viewModel.isAllValid
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isAllValid in
            guard let self = self else { return }
            self.signUpButton.isEnabled = isAllValid
        }
        .store(in: &disposeBag)

        viewModel.error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                let alertController = UIAlertController(for: error, title: "Sign Up Failure", preferredStyle: .alert)
                let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                alertController.addAction(okAction)
                self.coordinator.present(
                    scene: .alertController(alertController: alertController),
                    from: nil,
                    transition: .alertController(animated: true, completion: nil)
                )
            }
            .store(in: &disposeBag)

        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: usernameTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.username.value = self.usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: displayNameTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.displayName.value = self.displayNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: emailTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.email.value = self.emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: passwordTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.password.value = self.passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            .store(in: &disposeBag)

        signUpButton.addTarget(self, action: #selector(MastodonRegisterViewController.signUpButtonPressed(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

extension MastodonRegisterViewController: UITextFieldDelegate {

    // FIXME: keyboard listener trigger when switch between text fields. Maybe could remove it
    // func textFieldDidBeginEditing(_ textField: UITextField) {
    //     // align to password label when overlap
    //     if textField === passwordTextField,
    //        KeyboardResponderService.shared.isShow.value,
    //        KeyboardResponderService.shared.state.value == .dock
    //     {
    //         let endFrame = KeyboardResponderService.shared.willEndFrame.value
    //         let contentFrame = scrollView.convert(signUpButton.frame, to: nil)
    //         let padding = contentFrame.maxY - endFrame.minY
    //         if padding > 0 {
    //             let contentOffsetY = scrollView.contentOffset.y
    //             DispatchQueue.main.async {
    //                 self.scrollView.setContentOffset(CGPoint(x: 0, y: contentOffsetY + padding + 16.0), animated: true)
    //             }
    //         }
    //     }
    // }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        switch textField {
        case usernameTextField:
            viewModel.username.value = text
        case displayNameTextField:
            viewModel.displayName.value = text
        case emailTextField:
            viewModel.email.value = text
        case passwordTextField:
            viewModel.password.value = text
        default:
            break
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

    private func setTextFieldValidAppearance(_ textField: UITextField, validateState: MastodonRegisterViewModel.ValidateState) {
        switch validateState {
        case .empty:
            showShadowWithColor(color: textField.isFirstResponder ? Asset.Colors.TextField.highlight.color : .clear, textField: textField)
        case .valid:
            showShadowWithColor(color: Asset.Colors.TextField.valid.color, textField: textField)
        case .invalid:
            showShadowWithColor(color: Asset.Colors.TextField.invalid.color, textField: textField)
        }
    }
}

extension MastodonRegisterViewController {
    
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc private func signUpButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        guard viewModel.isAllValid.value else { return }
        
        guard !viewModel.isRegistering.value else { return }
        viewModel.isRegistering.value = true
    
        let username = viewModel.username.value
        let email = viewModel.email.value
        let password = viewModel.password.value
        
        if let rules = viewModel.instance.rules, !rules.isEmpty {
            let mastodonServerRulesViewModel = MastodonServerRulesViewModel(
                context: context,
                domain: viewModel.domain,
                rules: rules
            )
            coordinator.present(scene: .mastodonServerRules(viewModel: mastodonServerRulesViewModel), from: self, transition: .show)
            return
        }
        
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
            let userToken = response.value
            
            let alertController = UIAlertController(title: L10n.Scene.Register.success, message: L10n.Scene.Register.checkEmail, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default) { [weak self] _ in
                guard let self = self else { return }
                let viewModel = MastodonConfirmEmailViewModel(context: self.context, email: email, authenticateInfo: self.viewModel.authenticateInfo, userToken: userToken)
                self.coordinator.present(scene: .mastodonConfirmEmail(viewModel: viewModel), from: self, transition: .show)
            }
            alertController.addAction(okAction)
            self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
        }
        .store(in: &disposeBag)
    }
}
