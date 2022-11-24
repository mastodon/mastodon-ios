//
//  WelcomeViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class WelcomeViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "WelcomeViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private(set) lazy var viewModel = WelcomeViewModel(context: context)
    
    let welcomeIllustrationView = WelcomeIllustrationView()
    var welcomeIllustrationViewBottomAnchorLayoutConstraint: NSLayoutConstraint?
    
    private(set) lazy var dismissBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(WelcomeViewController.dismissBarButtonItemDidPressed(_:)))
    
    private(set) lazy var logoImageView: UIImageView = {
        let image = Asset.Scene.Welcome.mastodonLogo.image
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
    
    let buttonContainer = UIStackView()
    
    private(set) lazy var signUpButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.adjustsBackgroundImageWhenUserInterfaceStyleChanges = false
        button.contentEdgeInsets = WelcomeViewController.actionButtonPadding
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
        let backgroundImageColor: UIColor = .white
        let backgroundImageHighlightedColor: UIColor = UIColor(white: 0.8, alpha: 1.0)
        button.setBackgroundImage(.placeholder(color: backgroundImageColor), for: .normal)
        button.setBackgroundImage(.placeholder(color: backgroundImageHighlightedColor), for: .highlighted)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    let signUpButtonShadowView = UIView()
    
    private(set) lazy var signInButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.adjustsBackgroundImageWhenUserInterfaceStyleChanges = false
        button.contentEdgeInsets = WelcomeViewController.actionButtonPadding
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        button.setTitle(L10n.Scene.Welcome.logIn, for: .normal)
        let backgroundImageColor = Asset.Scene.Welcome.signInButtonBackground.color
        let backgroundImageHighlightedColor = Asset.Scene.Welcome.signInButtonBackground.color.withAlphaComponent(0.8)
        button.setBackgroundImage(.placeholder(color: backgroundImageColor), for: .normal)
        button.setBackgroundImage(.placeholder(color: backgroundImageHighlightedColor), for: .highlighted)
        let titleColor: UIColor = UIColor.white.withAlphaComponent(0.9)
        button.setTitleColor(titleColor, for: .normal)
        return button
    }()
    let signInButtonShadowView = UIView()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        preferredContentSize = CGSize(width: 547, height: 678)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .never
        view.overrideUserInterfaceStyle = .light
        
        setupOnboardingAppearance()
        setupIllustrationLayout()
        
        buttonContainer.axis = .vertical
        buttonContainer.spacing = 12
        buttonContainer.isLayoutMarginsRelativeArrangement = true
        
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        NSLayoutConstraint.activate([
            buttonContainer.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
        ])
        
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
        ])
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
        ])
        
        signUpButtonShadowView.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(signUpButtonShadowView)
        buttonContainer.sendSubviewToBack(signUpButtonShadowView)
        signUpButtonShadowView.pinTo(to: signUpButton)
        
        signInButtonShadowView.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(signInButtonShadowView)
        buttonContainer.sendSubviewToBack(signInButtonShadowView)
        signInButtonShadowView.pinTo(to: signInButton)

        signUpButton.addTarget(self, action: #selector(signUpButtonDidClicked(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInButtonDidClicked(_:)), for: .touchUpInside)
        
        viewModel.$needsShowDismissEntry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsShowDismissEntry in
                guard let self = self else { return }
                self.navigationItem.leftBarButtonItem = needsShowDismissEntry ? self.dismissBarButtonItem : nil
            }
            .store(in: &disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        setupButtonShadowView()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        var overlap: CGFloat = 5
        // shift illustration down for non-notch phone
        if view.safeAreaInsets.bottom == 0 {
            overlap += 56
        }
        welcomeIllustrationViewBottomAnchorLayoutConstraint?.constant = overlap
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.layoutIfNeeded()

        setupIllustrationLayout()
        setupButtonShadowView()
    }
        
}

extension WelcomeViewController {
    
    private func setupButtonShadowView() {
        signUpButtonShadowView.layer.setupShadow(
            color: .black,
            alpha: 0.25,
            x: 0,
            y: 1,
            blur: 2,
            spread: 0,
            roundedRect: signUpButtonShadowView.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: 10, height: 10)
        )
        signInButtonShadowView.layer.setupShadow(
            color: .black,
            alpha: 0.25,
            x: 0,
            y: 1,
            blur: 2,
            spread: 0,
            roundedRect: signInButtonShadowView.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: 10, height: 10)
        )
    }
    
    private func updateButtonContainerLayoutMargins(traitCollection: UITraitCollection) {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            buttonContainer.layoutMargins = UIEdgeInsets(
                top: 0,
                left: WelcomeViewController.actionButtonMargin,
                bottom: WelcomeViewController.viewBottomPaddingHeight,
                right: WelcomeViewController.actionButtonMargin
            )
        default:
            let margin = traitCollection.horizontalSizeClass == .regular ? WelcomeViewController.actionButtonMarginExtend : WelcomeViewController.actionButtonMargin
            buttonContainer.layoutMargins = UIEdgeInsets(
                top: 0,
                left: margin,
                bottom: WelcomeViewController.viewBottomPaddingHeightExtend,
                right: margin
            )
        }
    }
    
    private func setupIllustrationLayout() {
        welcomeIllustrationView.layout = {
            switch traitCollection.userInterfaceIdiom {
            case .phone:
                return .compact
            default:
                return .regular
            }
        }()
        
        // set logo
        if logoImageView.superview == nil {
            view.addSubview(logoImageView)
            NSLayoutConstraint.activate([
                logoImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
                logoImageView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 35),
                view.readableContentGuide.trailingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 35),
                logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 75.0/269.0),
            ])
            logoImageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        }
        
        // set illustration
        guard welcomeIllustrationView.superview == nil else {
            return
        }
        welcomeIllustrationView.contentMode = .scaleAspectFit
        
        welcomeIllustrationView.translatesAutoresizingMaskIntoConstraints = false
        welcomeIllustrationViewBottomAnchorLayoutConstraint = welcomeIllustrationView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 5)
        
        view.addSubview(welcomeIllustrationView)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: welcomeIllustrationView.leftAnchor, constant: 15),
            welcomeIllustrationView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 15),
            welcomeIllustrationViewBottomAnchorLayoutConstraint!.priority(.required - 1),
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
}

extension WelcomeViewController {
    @objc
    private func signUpButtonDidClicked(_ sender: UIButton) {
        _ = coordinator.present(scene: .mastodonPickServer(viewMode: MastodonPickServerViewModel(context: context)), from: self, transition: .show)
    }
    
    @objc
    private func signInButtonDidClicked(_ sender: UIButton) {
        _ = coordinator.present(scene: .mastodonLogin, from: self, transition: .show)
    }
    
    @objc
    private func dismissBarButtonItemDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension WelcomeViewController: OnboardingViewControllerAppearance {
    func setupNavigationBarAppearance() {
        // always transparent
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = barAppearance
        } else {
            // Fallback on earlier versions
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension WelcomeViewController: UIAdaptivePresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        // update button layout
        updateButtonContainerLayoutMargins(traitCollection: traitCollection)
        
        let navigationController = navigationController as? OnboardingNavigationController
        
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            navigationController?.gradientBorderView.isHidden = true
            // make underneath view controller alive to fix layout issue due to view life cycle
            return .fullScreen
        default:
            switch traitCollection.horizontalSizeClass {
            case .compact:
                navigationController?.gradientBorderView.isHidden = true
                return .fullScreen
            default:
                navigationController?.gradientBorderView.isHidden = false
                return .formSheet
            }
        }
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return nil
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
