//
//  MastodonConfirmEmailViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/23.
//

import Combine
import ThirdPartyMailer
import UIKit

final class MastodonConfirmEmailViewController: UIViewController, NeedsDependency {
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
        button.setTitleColor(.white, for: .normal)
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
    override func viewDidLoad() {
        overrideUserInterfaceStyle = .light
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        // set navigationBar transparent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarPosition.any, barMetrics: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.topItem?.title = "Back"

        // resizedView
        let resizedView = UIView()
        resizedView.translatesAutoresizingMaskIntoConstraints = false
        resizedView.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.vertical)

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
    }
}

extension MastodonConfirmEmailViewController {
    @objc private func openEmailButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.OpenEmailApp.alertTitle, message: L10n.Scene.ConfirmEmail.OpenEmailApp.alertDescription, preferredStyle: .alert)
        let openEmailAction = UIAlertAction(title: L10n.Scene.ConfirmEmail.Button.openEmailApp, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.showEmailAppAlert()
        }
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
        alertController.addAction(openEmailAction)
        alertController.addAction(cancelAction)

        self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }

    @objc private func dontReceiveButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: L10n.Scene.ConfirmEmail.DontReceiveEmail.alertTitle, message: L10n.Scene.ConfirmEmail.DontReceiveEmail.alertDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default) { _ in }
        alertController.addAction(okAction)
        self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }

    func showEmailAppAlert() {
        let clients = ThirdPartyMailClient.clients()
        let application = UIApplication.shared
        let avaliableClients = clients.filter { client -> Bool in
            ThirdPartyMailer.application(application, isMailClientAvailable: client)
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let alertAction = UIAlertAction(title: "Mail", style: .default) { _ in
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
