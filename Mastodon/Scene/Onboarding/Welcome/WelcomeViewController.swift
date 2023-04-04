//
//  WelcomeViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization

class WelcomeSeparatorView: UIView {
    let leftLine: UIView
    let rightLine: UIView
    let label: UILabel

    override init(frame: CGRect) {
        leftLine = UIView()
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        leftLine.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        rightLine = UIView()
        rightLine.translatesAutoresizingMaskIntoConstraints = false
        rightLine.backgroundColor = UIColor.white.withAlphaComponent(0.6)

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = NSAttributedString(
            string: L10n.Scene.Welcome.Separator.or.uppercased(),
            attributes: [
                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold)),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
        )

        super.init(frame: frame)

        addSubview(leftLine)
        addSubview(label)
        addSubview(rightLine)

        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        let constraints = [

            label.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: label.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.leadingAnchor.constraint(equalTo: leftLine.trailingAnchor, constant: 8),
            leftLine.centerYAnchor.constraint(equalTo: centerYAnchor),

            rightLine.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: rightLine.trailingAnchor),
            rightLine.centerYAnchor.constraint(equalTo: centerYAnchor),

            leftLine.heightAnchor.constraint(equalToConstant: 1),
            rightLine.heightAnchor.constraint(equalTo: leftLine.heightAnchor),

        ]
        NSLayoutConstraint.activate(constraints)
    }
}


final class WelcomeViewController: UIViewController, NeedsDependency {
    
    private enum Constants {
        static let topAnchorInset: CGFloat = 20
    }
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private(set) lazy var viewModel = WelcomeViewModel(context: context)
    
    let welcomeIllustrationView = WelcomeIllustrationView()
    
    private(set) lazy var dismissBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(WelcomeViewController.dismissBarButtonItemDidPressed(_:)))
    
    let buttonContainer = UIStackView()

    private(set) lazy var joinDefaultServerButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.attributedTitle = AttributedString(
            L10n.Scene.Welcome.joinDefaultServer,
            attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
        )
        buttonConfiguration.baseForegroundColor = .white
        buttonConfiguration.background.backgroundColor = Asset.Colors.Brand.blurple.color
        buttonConfiguration.background.cornerRadius = 14

        buttonConfiguration.contentInsets = .init(top: WelcomeViewController.actionButtonPadding.top,
                                                  leading: WelcomeViewController.actionButtonPadding.left,
                                                  bottom: WelcomeViewController.actionButtonPadding.bottom,
                                                  trailing: WelcomeViewController.actionButtonPadding.right)

        let button = UIButton(configuration: buttonConfiguration)
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        return button
    }()

    private(set) lazy var signUpButton: UIButton = {

        var buttonConfiguration = UIButton.Configuration.borderedTinted()
        buttonConfiguration.attributedTitle = AttributedString(
            L10n.Scene.Welcome.pickServer,
            attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
        )

        buttonConfiguration.background.cornerRadius = 14
        buttonConfiguration.background.strokeColor = UIColor.white.withAlphaComponent(0.6)
        buttonConfiguration.background.strokeWidth = 1
        buttonConfiguration.baseBackgroundColor = .clear
        buttonConfiguration.baseForegroundColor = .white

        buttonConfiguration.contentInsets = .init(top: WelcomeViewController.actionButtonPadding.top,
                                                  leading: WelcomeViewController.actionButtonPadding.left,
                                                  bottom: WelcomeViewController.actionButtonPadding.bottom,
                                                  trailing: WelcomeViewController.actionButtonPadding.right)

        let button = UIButton(configuration: buttonConfiguration)
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        return button
    }()

    private(set) lazy var signInButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.baseForegroundColor = .white
        buttonConfiguration.attributedTitle = AttributedString(
            L10n.Scene.Welcome.logIn,
            attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
        )

        let button = UIButton(configuration: buttonConfiguration)
        return button
    }()

    private(set) lazy var learnMoreButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.baseForegroundColor = .white
        buttonConfiguration.attributedTitle = AttributedString(
            L10n.Scene.Welcome.learnMore,
            attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
        )

        let button = UIButton(configuration: buttonConfiguration)
        return button
    }()
}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        preferredContentSize = CGSize(width: 547, height: 678)
        
        navigationController?.navigationBar.prefersLargeTitles = true /// enable large title support for this and all subsequent VCs
        navigationItem.largeTitleDisplayMode = .never
        
        view.overrideUserInterfaceStyle = .light
        
        setupOnboardingAppearance()
        
        view.addSubview(welcomeIllustrationView)
        welcomeIllustrationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            welcomeIllustrationView.topAnchor.constraint(equalTo: view.topAnchor),
            welcomeIllustrationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: welcomeIllustrationView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: welcomeIllustrationView.bottomAnchor)
        ])
        
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

        joinDefaultServerButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(joinDefaultServerButton)
        NSLayoutConstraint.activate([
            joinDefaultServerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
        ])

        
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
        ])

        buttonContainer.addArrangedSubview(WelcomeSeparatorView(frame: .zero))

        signInButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            signInButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
        ])

        learnMoreButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            learnMoreButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
        ])

        let bottomButtonStackView = UIStackView(arrangedSubviews: [learnMoreButton, signInButton])
        bottomButtonStackView.axis = .horizontal
        bottomButtonStackView.distribution = .fill
        bottomButtonStackView.alignment = .center
        bottomButtonStackView.spacing = 16

        buttonContainer.addArrangedSubview(bottomButtonStackView)

        joinDefaultServerButton.addTarget(self, action: #selector(joinDefaultServer(_:)), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(signUp(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)
        learnMoreButton.addTarget(self, action: #selector(learnMore(_:)), for: .touchUpInside)
        
        viewModel.$needsShowDismissEntry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsShowDismissEntry in
                guard let self = self else { return }
                self.navigationItem.leftBarButtonItem = needsShowDismissEntry ? self.dismissBarButtonItem : nil
            }
            .store(in: &disposeBag)
    }
    

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        var overlap: CGFloat = 5
        // shift illustration down for non-notch phone
        if view.safeAreaInsets.bottom == 0 {
            overlap += 56
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        view.layoutIfNeeded()
        
        setupIllustrationLayout()
    }
    
    private var computedTopAnchorInset: CGFloat {
        (navigationController?.navigationBar.bounds.height ?? UINavigationBar().bounds.height) + Constants.topAnchorInset
    }
}

extension WelcomeViewController {

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
        welcomeIllustrationView.setup()
    }
}

extension WelcomeViewController {

    //MARK: - Actions
    @objc
    private func joinDefaultServer(_ sender: UIButton) {
        sender.configuration?.title = nil
        sender.configuration?.showsActivityIndicator = true

        //TODO: do whatever MastodonPickServerViewController.next is doing but with default server
    }

    @objc
    private func signUp(_ sender: UIButton) {
        _ = coordinator.present(scene: .mastodonPickServer(viewMode: MastodonPickServerViewModel(context: context)), from: self, transition: .show)
    }
    
    @objc
    private func signIn(_ sender: UIButton) {
        _ = coordinator.present(scene: .mastodonLogin, from: self, transition: .show)
    }

    @objc
    private func learnMore(_ sender: UIButton) {
        //TODO: Show Education-part
    }

    @objc
    private func dismissBarButtonItemDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension WelcomeViewController: OnboardingViewControllerAppearance {}

// MARK: - UIAdaptivePresentationControllerDelegate
extension WelcomeViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
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

//MARK: - UICollectionViewDelegate
extension WelcomeViewController: UICollectionViewDelegate { }
