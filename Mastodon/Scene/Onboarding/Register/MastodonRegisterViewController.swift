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
    
    let scrollView: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.showsVerticalScrollIndicator = false
        scrollview.keyboardDismissMode = .interactive
        scrollview.alwaysBounceVertical = true
        scrollview.clipsToBounds = false    // make content could display over bleeding
        scrollview.translatesAutoresizingMaskIntoConstraints = false
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
        textField.textColor = Asset.Colors.Label.primary.color
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.Username.placeholder,
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.Label.secondary.color,
                                                                          NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)])
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    let usernameIsTakenLabel: UILabel = {
        let label = UILabel()
        let color = Asset.Colors.lightDangerRed.color
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let attributeString = NSMutableAttributedString()
        
        let errorImage = NSTextAttachment()
        let configuration = UIImage.SymbolConfiguration(font: font)
        errorImage.image = UIImage(systemName: "xmark.octagon.fill", withConfiguration: configuration)?.withTintColor(color)
        let errorImageAttachment = NSAttributedString(attachment: errorImage)
        attributeString.append(errorImageAttachment)
        
        let errorString = NSAttributedString(string: L10n.Common.Errors.Item.username + " " + L10n.Common.Errors.errTaken, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        attributeString.append(errorString)
        label.attributedText = attributeString
        
        return label
    }()
    
    let displayNameTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .white
        textField.textColor = Asset.Colors.Label.primary.color
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.DisplayName.placeholder,
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.Label.secondary.color,
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
        textField.textColor = Asset.Colors.Label.primary.color
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.Email.placeholder,
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.Label.secondary.color,
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
        textField.textColor = Asset.Colors.Label.primary.color
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.Password.placeholder,
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.Label.secondary.color,
                                                                          NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)])
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    lazy var inviteTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .white
        textField.textColor = Asset.Colors.Label.primary.color
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Scene.Register.Input.Invite.registrationUserInviteRequest,
                                                             attributes: [NSAttributedString.Key.foregroundColor: Asset.Colors.Label.secondary.color,
                                                                          NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)])
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    let buttonContainer = UIView()
    let signUpButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.isEnabled = false
        button.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
        return button
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonRegisterViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        defer { setupNavigationBarBackgroundView() }
        
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
        if self.viewModel.approvalRequired {
            stackView.addArrangedSubview(inviteTextField)
        }
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
        stackView.addArrangedSubview(buttonContainer)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            signUpButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: MastodonRegisterViewController.actionButtonMargin),
            buttonContainer.trailingAnchor.constraint(equalTo: signUpButton.trailingAnchor, constant: MastodonRegisterViewController.actionButtonMargin),
            buttonContainer.bottomAnchor.constraint(equalTo: signUpButton.bottomAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: MastodonRegisterViewController.actionButtonHeight).priority(.defaultHigh),
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
                let contentFrame = self.buttonContainer.convert(self.signUpButton.frame, to: nil)
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
                isRegistering ? self.signUpButton.showLoading() : self.signUpButton.stopLoading()
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
                guard let error = error as? Mastodon.API.Error else { return }
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

        if self.viewModel.approvalRequired {
            
            inviteTextField.delegate = self
            NSLayoutConstraint.activate([
                inviteTextField.heightAnchor.constraint(equalToConstant: 50).priority(.defaultHigh)
            ])
            
            viewModel.inviteValidateState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] validateState in
                    guard let self = self else { return }
                    self.setTextFieldValidAppearance(self.inviteTextField, validateState: validateState)

                }
                .store(in: &disposeBag)
            NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: inviteTextField)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.viewModel.reason.value = self.inviteTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                }
                .store(in: &disposeBag)
        }
        
        signUpButton.addTarget(self, action: #selector(MastodonRegisterViewController.signUpButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension MastodonRegisterViewController: UITextFieldDelegate {
    
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
        case inviteTextField:
            viewModel.reason.value = text
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
        let query = Mastodon.API.Account.RegisterQuery(
            reason: viewModel.reason.value,
            username: username,
            email: email,
            password: password,
            agreement: true, // TODO:
            locale: "en" // TODO:
        )
        
        if let rules = viewModel.instance.rules, !rules.isEmpty {
            // show server rules before register
            let mastodonServerRulesViewModel = MastodonServerRulesViewModel(
                context: context,
                domain: viewModel.domain,
                authenticateInfo: viewModel.authenticateInfo,
                rules: rules,
                registerQuery: query,
                applicationAuthorization: viewModel.applicationAuthorization
            )
            
            viewModel.isRegistering.value = false
            view.endEditing(true)
            coordinator.present(scene: .mastodonServerRules(viewModel: mastodonServerRulesViewModel), from: self, transition: .show)
            return
        } else {
            // register without show server rules
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
                let viewModel = MastodonConfirmEmailViewModel(context: self.context, email: email, authenticateInfo: self.viewModel.authenticateInfo, userToken: userToken)
                self.coordinator.present(scene: .mastodonConfirmEmail(viewModel: viewModel), from: self, transition: .show)
            }
            .store(in: &disposeBag)
        }
    }
}
