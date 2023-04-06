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
import MastodonSDK

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

    private(set) lazy var authenticationViewModel = AuthenticationViewModel(
        context: context,
        coordinator: coordinator,
        isAuthenticationExist: false
    )

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private(set) lazy var viewModel = WelcomeViewModel(context: context)
    
    let welcomeIllustrationView = WelcomeIllustrationView()
    var welcomeIllustrationViewBottomAnchorLayoutConstraint: NSLayoutConstraint?

    private(set) lazy var mastodonLogo: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.mastodonLogo.image)
        return imageView
    }()


    //TODO: Extract all those UI-elements in a UIView-subclass
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
        buttonConfiguration.activityIndicatorColorTransformer = UIConfigurationColorTransformer({ _ in
            return UIColor.white
        })

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

        mastodonLogo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mastodonLogo)

        NSLayoutConstraint.activate([
            mastodonLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            mastodonLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mastodonLogo.widthAnchor.constraint(equalToConstant: 300),
        ])

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

        welcomeIllustrationViewBottomAnchorLayoutConstraint?.constant = overlap
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
        welcomeIllustrationView.layout = {
            switch traitCollection.userInterfaceIdiom {
                case .phone:
                    return .compact
                default:
                    return .regular
            }
        }()

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
            topPaddingView.topAnchor.constraint(equalTo: mastodonLogo.bottomAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: mastodonLogo.leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: mastodonLogo.trailingAnchor),
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
            bottomPaddingView.leadingAnchor.constraint(equalTo: mastodonLogo.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: mastodonLogo.trailingAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: view.centerYAnchor),
            bottomPaddingView.heightAnchor.constraint(equalTo: topPaddingView.heightAnchor, multiplier: 4),
        ])

        welcomeIllustrationView.elephantOnAirplaneWithContrailImageView.addMotionEffect(
            UIInterpolatingMotionEffect.motionEffect(minX: -20, maxX: 12, minY: -20, maxY: 12)  // maxX should not larger then the bleeding (12pt)
        )

      }}

extension WelcomeViewController {

    //MARK: - Actions
    @objc
    private func joinDefaultServer(_ sender: UIButton) {
        sender.configuration?.title = nil
        sender.isEnabled = false
        sender.configuration?.showsActivityIndicator = true

        let server = Mastodon.Entity.Server.mastodonDotSocial

        authenticationViewModel.isAuthenticating.send(true)

        context.apiService.instance(domain: server.domain)
            .compactMap { [weak self] response -> AnyPublisher<MastodonPickServerViewModel.SignUpResponseFirst, Error>? in
                guard let self = self else { return nil }
                guard response.value.registrations != false else {
                    return Fail(error: AuthenticationViewModel.AuthenticationError.registrationClosed).eraseToAnyPublisher()
                }
                return self.context.apiService.createApplication(domain: server.domain)
                    .map { MastodonPickServerViewModel.SignUpResponseFirst(instance: response, application: $0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .tryMap { response -> MastodonPickServerViewModel.SignUpResponseSecond in
                let application = response.application.value
                guard let authenticateInfo = AuthenticationViewModel.AuthenticateInfo(
                        domain: server.domain,
                        application: application
                ) else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                return MastodonPickServerViewModel.SignUpResponseSecond(
                    instance: response.instance,
                    authenticateInfo: authenticateInfo
                )
            }
            .compactMap { [weak self] response -> AnyPublisher<MastodonPickServerViewModel.SignUpResponseThird, Error>? in
                guard let self = self else { return nil }
                let instance = response.instance
                let authenticateInfo = response.authenticateInfo
                return self.context.apiService.applicationAccessToken(
                    domain: server.domain,
                    clientID: authenticateInfo.clientID,
                    clientSecret: authenticateInfo.clientSecret,
                    redirectURI: authenticateInfo.redirectURI
                )
                .map {
                    MastodonPickServerViewModel.SignUpResponseThird(
                        instance: instance,
                        authenticateInfo: authenticateInfo,
                        applicationToken: $0
                    )
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.authenticationViewModel.isAuthenticating.send(false)

                switch completion {
                    case .failure(let error):
                        //TODO: show an alert or something
                        break
                    case .finished:
                        break
                }

                sender.isEnabled = true
                sender.configuration?.showsActivityIndicator = false
                sender.configuration?.attributedTitle = AttributedString(
                    L10n.Scene.Welcome.joinDefaultServer,
                    attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
                )
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if let rules = response.instance.value.rules, !rules.isEmpty {
                    // show server rules before register
                    let mastodonServerRulesViewModel = MastodonServerRulesViewModel(
                        domain: server.domain,
                        authenticateInfo: response.authenticateInfo,
                        rules: rules,
                        instance: response.instance.value,
                        applicationToken: response.applicationToken.value
                    )
                    _ = self.coordinator.present(scene: .mastodonServerRules(viewModel: mastodonServerRulesViewModel), from: self, transition: .show)
                } else {
                    let mastodonRegisterViewModel = MastodonRegisterViewModel(
                        context: self.context,
                        domain: server.domain,
                        authenticateInfo: response.authenticateInfo,
                        instance: response.instance.value,
                        applicationToken: response.applicationToken.value
                    )
                    _ = self.coordinator.present(scene: .mastodonRegister(viewModel: mastodonRegisterViewModel), from: nil, transition: .show)
                }
            }
            .store(in: &disposeBag)

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
        let educationViewController = EducationViewController()
        educationViewController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = educationViewController.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
            sheetPresentationController.prefersGrabberVisible = true
        }

        present(educationViewController, animated: true)
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
