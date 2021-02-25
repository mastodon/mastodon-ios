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

final class MastodonConfirmEmailViewController: UIViewController, NeedsDependency, OnboardingViewControllerAppearance {
    var disposeBag = Set<AnyCancellable>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var viewModel: MastodonConfirmEmailViewModel!

    let largeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: UIFont.boldSystemFont(ofSize: 34))
        label.textColor = .label
        label.text = L10n.Scene.ConfirmEmail.title
        return label
    }()

    private(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont.systemFont(ofSize: 20))
        label.textColor = .secondaryLabel
        label.text = L10n.Scene.ConfirmEmail.subtitle(viewModel.email)
        label.numberOfLines = 0
        return label
    }()

    let openEmailButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.lightBrandBlue.color), for: .normal)
        button.setTitleColor(Asset.Colors.Label.primary.color, for: .normal)
        button.setTitle(L10n.Scene.ConfirmEmail.Button.openEmailApp, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: #selector(openEmailButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        return button
    }()

    let dontReceiveButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.boldSystemFont(ofSize: 15))
        button.setTitleColor(Asset.Colors.lightBrandBlue.color, for: .normal)
        button.setTitle(L10n.Scene.ConfirmEmail.Button.dontReceiveEmail, for: .normal)
        button.addTarget(self, action: #selector(dontReceiveButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        return button
    }()
}

extension MastodonConfirmEmailViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLoad() {

        self.setupOnboardingAppearance()
        
        // resizedView
        let resizedView = UIView()
        resizedView.translatesAutoresizingMaskIntoConstraints = false
        resizedView.setContentHuggingPriority(.defaultLow, for: .vertical)

        // stackView
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 23, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(self.largeTitleLabel)
        stackView.addArrangedSubview(self.subtitleLabel)
        stackView.addArrangedSubview(resizedView)
        stackView.addArrangedSubview(self.openEmailButton)
        stackView.addArrangedSubview(self.dontReceiveButton)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor),
        ])
        NSLayoutConstraint.activate([
            self.openEmailButton.heightAnchor.constraint(equalToConstant: 46),
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
                            break
                        }
                    } receiveValue: { _ in
                        self.coordinator.setup()
                    }
                    .store(in: &self.disposeBag)
            }
            .store(in: &self.disposeBag)
    }
}

extension MastodonConfirmEmailViewController {
    @objc private func openEmailButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.OpenEmailApp.title, message: L10n.Scene.ConfirmEmail.OpenEmailApp.description, preferredStyle: .alert)
        let openEmailAction = UIAlertAction(title: L10n.Scene.ConfirmEmail.Button.openEmailApp, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.showEmailAppAlert()
        }
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
        alertController.addAction(openEmailAction)
        alertController.addAction(cancelAction)
        alertController.preferredAction = openEmailAction
        self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }

    @objc private func dontReceiveButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.title, message: L10n.Scene.ConfirmEmail.DontReceiveEmail.description, preferredStyle: .alert)
        let resendAction = UIAlertAction(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.resendEmail, style: .default) { _ in
            let url = Mastodon.API.resendEmailURL(domain: self.viewModel.authenticateInfo.domain)
            let viewModel = MastodonResendEmailViewModel(resendEmailURL: url, email: self.viewModel.email)
            self.coordinator.present(scene: .mastodonResendEmail(viewModel: viewModel), from: self, transition: .modal(animated: true, completion: nil))
        }
        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default) { _ in
        }
        alertController.addAction(resendAction)
        alertController.addAction(okAction)
        self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }

    func showEmailAppAlert() {
        let clients = ThirdPartyMailClient.clients()
        let application = UIApplication.shared
        let avaliableClients = clients.filter { client -> Bool in
            ThirdPartyMailer.application(application, isMailClientAvailable: client)
        }
        let alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.OpenEmailApp.openEmailClient, message: nil, preferredStyle: .alert)

        let alertAction = UIAlertAction(title: L10n.Scene.ConfirmEmail.OpenEmailApp.mail, style: .default) { _ in
            UIApplication.shared.open(URL(string: "message://")!, options: [:], completionHandler: nil)
        }
        alertController.addAction(alertAction)
        _ = avaliableClients.compactMap { client -> UIAlertAction in
            let alertAction = UIAlertAction(title: client.name, style: .default) { _ in
                _ = ThirdPartyMailer.application(application, openMailClient: client, recipient: nil, subject: nil, body: nil)
            }
            alertController.addAction(alertAction)
            return alertAction
        }
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }
}
