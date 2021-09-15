//
//  WelcomeViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import os.log
import UIKit
import Combine

final class WelcomeViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = WelcomeViewModel(context: context)
    
    let welcomeIllustrationView = WelcomeIllustrationView()
    var welcomeIllustrationViewBottomAnchorLayoutConstraint: NSLayoutConstraint?
    
    private(set) lazy var dismissBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(WelcomeViewController.dismissBarButtonItemDidPressed(_:)))
    
    private(set) lazy var logoImageView: UIImageView = {
        let image = view.traitCollection.userInterfaceIdiom == .phone ? Asset.Scene.Welcome.mastodonLogo.image : Asset.Scene.Welcome.mastodonLogoBlackLarge.image
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private(set) lazy var sloganLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Welcome.slogan
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    private(set) lazy var  signUpButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.adjustsBackgroundImageWhenUserInterfaceStyleChanges = false
        button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
        let backgroundImageColor: UIColor = traitCollection.userInterfaceIdiom == .phone ? .white : Asset.Colors.brandBlue.color
        let backgroundImageHighlightedColor: UIColor = traitCollection.userInterfaceIdiom == .phone ? UIColor(white: 0.8, alpha: 1.0) : Asset.Colors.brandBlueDarken20.color
        button.setBackgroundImage(.placeholder(color: backgroundImageColor), for: .normal)
        button.setBackgroundImage(.placeholder(color: backgroundImageHighlightedColor), for: .highlighted)
        let titleColor: UIColor = traitCollection.userInterfaceIdiom == .phone ? Asset.Colors.brandBlue.color : UIColor.white
        button.setTitleColor(titleColor, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private(set) lazy var signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle(L10n.Common.Controls.Actions.signIn, for: .normal)
        let titleColor: UIColor = traitCollection.userInterfaceIdiom == .phone ? UIColor.white.withAlphaComponent(0.8) : Asset.Colors.brandBlue.color
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
        
        view.overrideUserInterfaceStyle = .light
        
        setupOnboardingAppearance()
        setupIllustrationLayout()

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
        
        viewModel.needsShowDismissEntry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsShowDismissEntry in
                guard let self = self else { return }
                self.navigationItem.leftBarButtonItem = needsShowDismissEntry ? self.dismissBarButtonItem : nil
            }
            .store(in: &disposeBag)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        // shift illustration down for non-notch phone
        var overlap: CGFloat = 5
        if view.safeAreaInsets.bottom == 0 {
            overlap += 56
        }
        welcomeIllustrationViewBottomAnchorLayoutConstraint?.constant = overlap
    }
        
}

extension WelcomeViewController {
    
    private func setupIllustrationLayout() {
        // set logo
        if logoImageView.superview == nil {
            view.addSubview(logoImageView)
            NSLayoutConstraint.activate([
                logoImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
                logoImageView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 35),
                view.readableContentGuide.trailingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 35),
                logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 65.4/265.1),
            ])
            logoImageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        }
        
        // set illustration for phone
        if traitCollection.userInterfaceIdiom == .phone {
            guard welcomeIllustrationView.superview == nil else {
                return
            }
            
            welcomeIllustrationView.translatesAutoresizingMaskIntoConstraints = false
            welcomeIllustrationViewBottomAnchorLayoutConstraint = welcomeIllustrationView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 5)

            view.addSubview(welcomeIllustrationView)
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: welcomeIllustrationView.leftAnchor, constant: 15),
                welcomeIllustrationView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 15),
                welcomeIllustrationViewBottomAnchorLayoutConstraint!
            ])
            
            welcomeIllustrationView.cloudBaseImageView.addMotionEffect(
                UIInterpolatingMotionEffect.motionEffect(minX: -5, maxX: 5, minY: -5, maxY: 5)
            )
            welcomeIllustrationView.rightHillImageView.addMotionEffect(
                UIInterpolatingMotionEffect.motionEffect(minX: -15, maxX: 25, minY: -10, maxY: 10)
            )
            welcomeIllustrationView.leftHillImageView.addMotionEffect(
                UIInterpolatingMotionEffect.motionEffect(minX: -25, maxX: 15, minY: -15, maxY: 15)
            )
            welcomeIllustrationView.centerHillImageView.addMotionEffect(
                UIInterpolatingMotionEffect.motionEffect(minX: -14, maxX: 14, minY: -5, maxY: 25)
            )

            let topPaddingView = UIView()
            topPaddingView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(topPaddingView)
            NSLayoutConstraint.activate([
                topPaddingView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor),
                topPaddingView.leadingAnchor.constraint(equalTo: logoImageView.leadingAnchor),
                topPaddingView.trailingAnchor.constraint(equalTo: logoImageView.trailingAnchor),
            ])
            welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(welcomeIllustrationView.elephantOnAirplaneWithContrailImageView)
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.leftAnchor, constant: 12),  // add 12pt bleeding
                welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
                // make a little bit large
                welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.84),
                welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.heightAnchor.constraint(equalTo: welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.widthAnchor, multiplier: 105.0/318.0),
            ])
            let bottomPaddingView = UIView()
            bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bottomPaddingView)
            NSLayoutConstraint.activate([
                bottomPaddingView.topAnchor.constraint(equalTo: welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.bottomAnchor),
                bottomPaddingView.leadingAnchor.constraint(equalTo: logoImageView.leadingAnchor),
                bottomPaddingView.trailingAnchor.constraint(equalTo: logoImageView.trailingAnchor),
                bottomPaddingView.bottomAnchor.constraint(equalTo: view.centerYAnchor),
                bottomPaddingView.heightAnchor.constraint(equalTo: topPaddingView.heightAnchor, multiplier: 4),
            ])

            welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.addMotionEffect(
                UIInterpolatingMotionEffect.motionEffect(minX: -20, maxX: 12, minY: -20, maxY: 12)  // maxX should not larger then the bleeding (12pt)
            )

            view.bringSubviewToFront(logoImageView)
            view.bringSubviewToFront(sloganLabel)
        }

        // set slogan for non-phone
        if traitCollection.userInterfaceIdiom != .phone {
            guard sloganLabel.superview == nil else {
                return
            }
            view.addSubview(sloganLabel)
            NSLayoutConstraint.activate([
                sloganLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 16),
                view.readableContentGuide.trailingAnchor.constraint(equalTo: sloganLabel.trailingAnchor, constant: 16),
                sloganLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 168),
            ])
        }
        
        view.bringSubviewToFront(sloganLabel)
        view.bringSubviewToFront(logoImageView)
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
    
    @objc
    private func dismissBarButtonItemDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension WelcomeViewController: OnboardingViewControllerAppearance { }

// MARK: - UIAdaptivePresentationControllerDelegate
extension WelcomeViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // make underneath view controller alive to fix layout issue due to view life cycle
        return .fullScreen
    }
}
