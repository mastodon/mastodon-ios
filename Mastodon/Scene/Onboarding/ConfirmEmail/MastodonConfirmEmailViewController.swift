//
//  MastodonConfirmEmailViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/23.
//

import Combine
import MastodonSDK
import os.log
import ThirdPartyMailer
import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class MastodonConfirmEmailViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

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
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.attributedTitle = try! AttributedString(markdown: "Didn't get a link? **Resend (10)**")

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

        subtitleLabel.text = L10n.Scene.ConfirmEmail.tapTheLinkWeEmailedToYouToVerifyYourAccount(viewModel.email)

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
                guard let self = self else { return }
                AuthenticationViewModel.verifyAndSaveAuthentication(context: self.context, info: self.viewModel.authenticateInfo, userToken: self.viewModel.userToken)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: swap user access token swap fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        case .finished:
                            // upload avatar and set display name in the background
                            Just(self.viewModel.userToken.accessToken)
                                .asyncMap { token in
                                    try await self.context.apiService.accountUpdateCredentials(
                                        domain: self.viewModel.authenticateInfo.domain,
                                        query: self.viewModel.updateCredentialQuery,
                                        authorization: Mastodon.API.OAuth.Authorization(accessToken: token)
                                    )
                                }
                                .retry(3)
                                .sink { completion in
                                    switch completion {
                                    case .failure(let error):
                                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: setup avatar & display name fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                                    case .finished:
                                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: setup avatar & display name success", ((#file as NSString).lastPathComponent), #line, #function)
                                    }
                                } receiveValue: { _ in
                                    // do nothing
                                }
                                .store(in: &self.context.disposeBag)    // execute in the background
                        }   // end switch
                    } receiveValue: { response in
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user %s's email confirmed", ((#file as NSString).lastPathComponent), #line, #function, response.value.username)
                        self.coordinator.setup()
                        // self.dismiss(animated: true, completion: nil)
                    }
                    .store(in: &self.disposeBag)
            }
            .store(in: &self.disposeBag)
        
        title = L10n.Scene.ConfirmEmail.title
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configureMargin()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // start timer
        let nowIn60Seconds = Date().addingTimeInterval(10)

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] in 
            guard Date() < nowIn60Seconds else {
                // enable button
                self?.resendEmailButton.isEnabled = true

                var configuration = self?.resendEmailButton.configuration
                let attributedTitle = try! AttributedString(markdown: "Didn't get a link? **Resend**")

                configuration?.attributedTitle = attributedTitle
                self?.resendEmailButton.configuration = configuration
                self?.resendEmailButton.setNeedsUpdateConfiguration()

                $0.invalidate()
                return
            }

            //TODO: @zeitschlag Add localization
            //TODO: @zeitschlag Add styling
            var configuration = self?.resendEmailButton.configuration
            let attributedTitle = try! AttributedString(markdown: "Didn't get a link? **Resend (\(Int(nowIn60Seconds.timeIntervalSinceNow) + 1))**")

            configuration?.attributedTitle = attributedTitle
            self?.resendEmailButton.configuration = configuration
            self?.resendEmailButton.setNeedsUpdateConfiguration()
        }

        RunLoop.main.add(timer, forMode: .default)
//        self.resendButtonTimer = timer
    }
}

extension MastodonConfirmEmailViewController {
    private func configureMargin() {
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
            let url = Mastodon.API.resendEmailURL(domain: self.viewModel.authenticateInfo.domain)
            let viewModel = MastodonResendEmailViewModel(resendEmailURL: url, email: self.viewModel.email)
            _ = self.coordinator.present(scene: .mastodonResendEmail(viewModel: viewModel), from: self, transition: .modal(animated: true, completion: nil))
        }
        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default) { _ in
        }
        alertController.addAction(resendAction)
        alertController.addAction(okAction)
        _ = self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
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
