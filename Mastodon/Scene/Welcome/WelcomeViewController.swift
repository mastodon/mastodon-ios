//
//  WelcomeViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import os.log
import UIKit

final class WelcomeViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    #if DEBUG
    let authenticationViewController = AuthenticationViewController()
    #endif
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.welcomeLogo.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let sloganLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: UIFont.boldSystemFont(ofSize: 34))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Welcome.slogan
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let signUpButton: PrimaryActionButton = {
        let button = PrimaryActionButton(type: .system)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle(L10n.Common.Controls.Actions.signIn, for: .normal)
        button.setTitleColor(Asset.Colors.lightBrandBlue.color, for: .normal)
        button.setInsets(forContentPadding: UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0), imageTitlePadding: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 35),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 35),
            logoImageView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor, constant: 46),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 65.4/265.1),
        ])
        
        view.addSubview(sloganLabel)
        NSLayoutConstraint.activate([
            sloganLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 16),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: sloganLabel.trailingAnchor, constant: 16),
            sloganLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 168),
        ])
        
        view.addSubview(signInButton)
        view.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signInButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 12),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor, constant: 12),
            view.readableContentGuide.bottomAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 11),
            
            signUpButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 12),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: signUpButton.trailingAnchor, constant: 12),
            signInButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 5)
        ])
        
        signUpButton.addTarget(self, action: #selector(signUpButtonDidClicked(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInButtonDidClicked(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
}

extension WelcomeViewController {

    @objc private func signInButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        #if DEBUG
        authenticationViewController.context = context
        authenticationViewController.coordinator = coordinator
        authenticationViewController.viewModel = AuthenticationViewModel(context: context, coordinator: coordinator, isAuthenticationExist: true)
        authenticationViewController.viewModel.domain.value = "pawoo.net"
        let _ = authenticationViewController.view   // trigger view load
        authenticationViewController.signInButton.sendActions(for: .touchUpInside)
        #endif
    }
    
    @objc private func signUpButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension WelcomeViewController {
    @objc
    private func signUpButtonDidClicked(_ sender: UIButton) {
        coordinator.present(scene: .pickServer(viewMode: PickServerViewModel(context: context, mode: .SignUp)), from: self, transition: .show)
    }
    
    @objc
    private func signInButtonDidClicked(_ sender: UIButton) {
        coordinator.present(scene: .pickServer(viewMode: PickServerViewModel(context: context, mode: .SignIn)), from: self, transition: .show)
    }
}
