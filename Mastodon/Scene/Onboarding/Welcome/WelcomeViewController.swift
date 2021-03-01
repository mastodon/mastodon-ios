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
    
    let welcomeIllustrationView = WelcomeIllustrationView()
    var welcomeIllustrationViewBottomAnchorLayoutConstraint: NSLayoutConstraint?
    
    private(set) lazy var logoImageView: UIImageView = {
        let image = view.traitCollection.userInterfaceIdiom == .phone ? Asset.Welcome.mastodonLogo.image : Asset.Welcome.mastodonLogoLarge.image
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let sloganLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Welcome.slogan
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let signUpButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private(set) lazy var signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle(L10n.Common.Controls.Actions.signIn, for: .normal)
        let titleColor: UIColor = traitCollection.userInterfaceIdiom == .phone ? UIColor.white.withAlphaComponent(0.8) : Asset.Colors.Button.highlight.color
        button.setTitleColor(titleColor, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        
        if traitCollection.userInterfaceIdiom == .phone {
            view.backgroundColor = Asset.Welcome.Illustration.backgroundCyan.color
            welcomeIllustrationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(welcomeIllustrationView)
            welcomeIllustrationViewBottomAnchorLayoutConstraint = welcomeIllustrationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: welcomeIllustrationView.leftAnchor, constant: 44),
                welcomeIllustrationView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 44),
                welcomeIllustrationViewBottomAnchorLayoutConstraint!,
            ])
        }
        
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            logoImageView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 35),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 35),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 65.4/265.1),
        ])
        
        view.addSubview(sloganLabel)
        NSLayoutConstraint.activate([
            sloganLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 16),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: sloganLabel.trailingAnchor, constant: 16),
            sloganLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 168),
        ])
        
        if traitCollection.userInterfaceIdiom == .phone {
            let imageSizeScale: CGFloat = view.frame.width > 375 ? 1.5 : 1.0
            welcomeIllustrationView.cloudFirstImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(welcomeIllustrationView.cloudFirstImageView)
            NSLayoutConstraint.activate([
                welcomeIllustrationView.cloudFirstImageView.rightAnchor.constraint(equalTo: view.centerXAnchor),
                welcomeIllustrationView.cloudFirstImageView.widthAnchor.constraint(equalToConstant: 272 / traitCollection.displayScale * imageSizeScale),
                welcomeIllustrationView.cloudFirstImageView.heightAnchor.constraint(equalToConstant: 113 / traitCollection.displayScale * imageSizeScale),
            ])
            welcomeIllustrationView.cloudSecondImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(welcomeIllustrationView.cloudSecondImageView)
            NSLayoutConstraint.activate([
                welcomeIllustrationView.cloudSecondImageView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor),
                welcomeIllustrationView.cloudSecondImageView.rightAnchor.constraint(equalTo: logoImageView.rightAnchor, constant: 20),
                welcomeIllustrationView.cloudSecondImageView.widthAnchor.constraint(equalToConstant: 152 / traitCollection.displayScale),
                welcomeIllustrationView.cloudSecondImageView.heightAnchor.constraint(equalToConstant: 96 / traitCollection.displayScale),
                welcomeIllustrationView.cloudFirstImageView.topAnchor.constraint(equalTo: welcomeIllustrationView.cloudSecondImageView.bottomAnchor),
            ])
            welcomeIllustrationView.cloudThirdImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(welcomeIllustrationView.cloudThirdImageView)
            NSLayoutConstraint.activate([
                logoImageView.topAnchor.constraint(equalTo: welcomeIllustrationView.cloudThirdImageView.bottomAnchor, constant: 10),
                welcomeIllustrationView.cloudThirdImageView.rightAnchor.constraint(equalTo: view.centerXAnchor),
                welcomeIllustrationView.cloudThirdImageView.widthAnchor.constraint(equalToConstant: 126 / traitCollection.displayScale),
                welcomeIllustrationView.cloudThirdImageView.heightAnchor.constraint(equalToConstant: 68 / traitCollection.displayScale),
            ])
            
            welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(welcomeIllustrationView.elephantOnAirplaneWithContrailImageView)
            NSLayoutConstraint.activate([
                welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
                welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.bottomAnchor.constraint(equalTo: sloganLabel.topAnchor),
                // make a little bit large
                welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.widthAnchor.constraint(equalToConstant: 656 / traitCollection.displayScale * imageSizeScale),
                welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.heightAnchor.constraint(equalToConstant: 195 / traitCollection.displayScale * imageSizeScale),
            ])
            view.bringSubviewToFront(logoImageView)
            view.bringSubviewToFront(sloganLabel)
        }
        
        view.addSubview(signInButton)
        view.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signInButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: WelcomeViewController.actionButtonMargin),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor, constant: WelcomeViewController.actionButtonMargin),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: WelcomeViewController.viewBottomPaddingHeight),
            signInButton.heightAnchor.constraint(equalToConstant: WelcomeViewController.actionButtonHeight).priority(.defaultHigh),
            
            signInButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 9),
            signUpButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: WelcomeViewController.actionButtonMargin),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: signUpButton.trailingAnchor, constant: WelcomeViewController.actionButtonMargin),
            signUpButton.heightAnchor.constraint(equalToConstant: WelcomeViewController.actionButtonHeight).priority(.defaultHigh),
        ])
        
        signUpButton.addTarget(self, action: #selector(signUpButtonDidClicked(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInButtonDidClicked(_:)), for: .touchUpInside)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        // make illustration bottom over the bleeding
        let overlap: CGFloat = 145
        welcomeIllustrationViewBottomAnchorLayoutConstraint?.constant = overlap - view.safeAreaInsets.bottom
    }
        
}

extension WelcomeViewController {
    @objc
    private func signUpButtonDidClicked(_ sender: UIButton) {
        coordinator.present(scene: .mastodonPickServer(viewMode: MastodonPickServerViewModel(context: context, mode: .signUp)), from: self, transition: .show)
    }
    
    @objc
    private func signInButtonDidClicked(_ sender: UIButton) {
        coordinator.present(scene: .mastodonPickServer(viewMode: MastodonPickServerViewModel(context: context, mode: .signIn)), from: self, transition: .show)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension WelcomeViewController: OnboardingViewControllerAppearance { }

// MARK: - UIAdaptivePresentationControllerDelegate
extension WelcomeViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}
