//
//  MastodonConfirmEmailViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/23.
//

import Combine
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class MastodonConfirmEmailViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()

    var viewModel: MastodonConfirmEmailViewModel!

    let stackView = UIStackView()

    private(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 17))
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    let emailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.Asset.email.image
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let resendEmailButton: UIButton = {

        let boldFont = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))
        let regularFont = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))

        var buttonConfiguration = UIButton.Configuration.plain()
        var boldResendString = AttributedString(L10n.Scene.ConfirmEmail.DidntGetLink.resendIn(60), attributes: .init([.font: boldFont]))
        var attributedTitle = AttributedString(L10n.Scene.ConfirmEmail.DidntGetLink.prefix, attributes: .init([.font: regularFont]))

        attributedTitle.append(AttributedString(" "))
        attributedTitle.append(boldResendString)

        buttonConfiguration.attributedTitle = attributedTitle

        let button = UIButton(configuration: buttonConfiguration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false

        return button
    }()

    var resendButtonTimer: Timer?
}

extension MastodonConfirmEmailViewController {

    override func viewDidLoad() {
        setupOnboardingAppearance()
        configureMargin()
        registerForTraitChanges([UITraitHorizontalSizeClass.self], action: #selector(configureMargin))

        if let email = viewModel.email {
            subtitleLabel.text = L10n.Scene.ConfirmEmail.tapTheLinkWeEmailedToYouToVerifyYourAccount(email)
        } else {
            subtitleLabel.text = L10n.Scene.ConfirmEmail.tapTheLinkWeEmailedToYou
        }

        resendEmailButton.addTarget(self, action: #selector(MastodonConfirmEmailViewController.resendButtonPressed(_:)), for: .touchUpInside)

        // stackView
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 23, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(emailImageView)
        stackView.addArrangedSubview(resendEmailButton)
        emailImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        emailImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor),
        ])
        
        self.viewModel.timestampUpdatePublisher
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    guard (try? await AuthenticationViewModel.verifyAndActivateAuthentication(info: self.viewModel.authenticateInfo, userToken: self.viewModel.userToken)) != nil else { return /* email confirmation not completed yet */ }
                    let domain = self.viewModel.authenticateInfo.domain
                    if let updateCredentialQuery = self.viewModel.updateCredentialQuery {
                        Task {
                            // in the background, set display name already chosen during set up
                            let _ = try? await APIService.shared.accountUpdateCredentials(
                                domain: domain,
                                query: updateCredentialQuery,
                                authorization: Mastodon.API.OAuth.Authorization(accessToken: self.viewModel.userToken.accessToken, domain: domain)
                            )
                        }
                    }
                    self.dismiss(animated: true, completion: nil) // dismiss this view
                }
            }
            .store(in: &self.disposeBag)
        
        title = L10n.Scene.ConfirmEmail.title
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let nowIn60Seconds = Date().addingTimeInterval(60)
        let boldFont = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))
        let regularFont = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        let digitFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .monospacedDigitSystemFont(ofSize: 15, weight: .bold))
        
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] in 
            guard Date() < nowIn60Seconds else {
                self?.resendEmailButton.isEnabled = true

                var configuration = self?.resendEmailButton.configuration

                let boldResendString = AttributedString(L10n.Scene.ConfirmEmail.DidntGetLink.resendNow, attributes: .init([.font: boldFont]))
                var attributedTitle = AttributedString(L10n.Scene.ConfirmEmail.DidntGetLink.prefix, attributes: .init([.font: regularFont]))

                attributedTitle.append(AttributedString(" "))
                attributedTitle.append(boldResendString)

                configuration?.attributedTitle = attributedTitle
                self?.resendEmailButton.configuration = configuration
                self?.resendEmailButton.setNeedsUpdateConfiguration()

                $0.invalidate()
                return
            }

            var configuration = self?.resendEmailButton.configuration

            let boldResendString = AttributedString(L10n.Scene.ConfirmEmail.DidntGetLink.resendIn(Int(nowIn60Seconds.timeIntervalSinceNow) + 1), attributes: .init([.font: digitFont]))
            var attributedTitle = AttributedString(L10n.Scene.ConfirmEmail.DidntGetLink.prefix, attributes: .init([.font: regularFont]))

            attributedTitle.append(AttributedString(" "))
            attributedTitle.append(boldResendString)

            configuration?.attributedTitle = attributedTitle
            self?.resendEmailButton.configuration = configuration
            self?.resendEmailButton.setNeedsUpdateConfiguration()
        }

        RunLoop.main.add(timer, forMode: .default)
    }
}

extension MastodonConfirmEmailViewController {
    @objc func configureMargin() {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            let margin = MastodonConfirmEmailViewController.viewEdgeMargin
            stackView.layoutMargins = UIEdgeInsets(top: 18, left: margin, bottom: 23, right: margin)
        default:
            stackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 23, right: 0)
        }
    }
}

extension MastodonConfirmEmailViewController {
    @objc private func resendButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.title, message: L10n.Scene.ConfirmEmail.DontReceiveEmail.description, preferredStyle: .alert)
        let resendAction = UIAlertAction(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.resendEmail, style: .default) { _ in
            guard let email = self.viewModel.email else {
                self.resendConfirmationEmail()
                return
            }
            let url = Mastodon.API.resendEmailURL(domain: self.viewModel.authenticateInfo.domain)
            let viewModel = MastodonResendEmailViewModel(resendEmailURL: url, email: email)
            _ = self.sceneCoordinator?.present(scene: .mastodonResendEmail(viewModel: viewModel), from: self, transition: .modal(animated: true, completion: nil))
        }
        let changeEmailAddressAction = UIAlertAction(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.changeEmail, style: .default) { _ in
            self.askForCorrectedEmail()
        }
        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default) { _ in
        }
        alertController.addAction(resendAction)
        alertController.addAction(changeEmailAddressAction)
        alertController.addAction(okAction)
        _ = self.sceneCoordinator?.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }
    
    private func resendConfirmationEmail(changingEmailTo updatedEmail: String? = nil) {
        let domain = viewModel.authenticateInfo.domain
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: viewModel.userToken.accessToken, domain: domain)
        Task { @MainActor in
            let alertController: UIAlertController
            do {
                try await APIService.shared.resendConfirmationEmail(domain: domain, email: updatedEmail, authorization: authorization)
                if let updatedEmail {
                    self.viewModel.email = updatedEmail
                    self.subtitleLabel.text = L10n.Scene.ConfirmEmail.tapTheLinkWeEmailedToYouToVerifyYourAccount(updatedEmail)
                }
                alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.OpenEmailApp.title, message: L10n.Scene.ConfirmEmail.OpenEmailApp.description, preferredStyle: .alert)
            } catch {
                alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
            }
            alertController.addAction(UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default))
            _ = self.sceneCoordinator?.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
        }
    }
    
    private func askForCorrectedEmail() {
        let alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.changeEmail, message: nil, preferredStyle: .alert)
        let sendAction = UIAlertAction(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.resendEmail, style: .default) { [weak self, weak alertController] _ in
            guard let email = alertController?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else { return }
            self?.resendConfirmationEmail(changingEmailTo: email)
        }
        sendAction.isEnabled = viewModel.email?.isEmpty == false
        alertController.addTextField { [weak self] textField in
            textField.placeholder = L10n.Scene.Register.Input.Email.placeholder
            textField.text = self?.viewModel.email
            textField.keyboardType = .emailAddress
            textField.textContentType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.addAction(
                UIAction {  [weak sendAction, weak textField] _ in
                    sendAction?.isEnabled = !((textField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty)
                }, for: .editingChanged)
        }
        alertController.addAction(UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel))
        alertController.addAction(sendAction)
        alertController.preferredAction = sendAction
        _ = self.sceneCoordinator?.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }
}

// MARK: - PanPopableViewController
extension MastodonConfirmEmailViewController: PanPopableViewController {
    var isPanPopable: Bool { false }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonConfirmEmailViewController: OnboardingViewControllerAppearance { }

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct MastodonConfirmEmailViewController_Previews: PreviewProvider {
    
    static var controls: some View {
        UIViewControllerPreview {
            let viewController = MastodonConfirmEmailViewController()
            return viewController
        }
        .previewLayout(.fixed(width: 375, height: 800))
    }
    
    static var previews: some View {
            Group {
                controls.colorScheme(.light)
                controls.colorScheme(.dark)
            }
    }
    
}

#endif
