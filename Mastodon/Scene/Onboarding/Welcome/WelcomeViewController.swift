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
    let separatorView = WelcomeSeparatorView(frame: .zero)

    private(set) lazy var mastodonLogo: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.mastodonLogo.image)
        return imageView
    }()


    //TODO: Extract all those UI-elements in a UIView-subclass
    private(set) lazy var dismissBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(WelcomeViewController.dismissBarButtonItemDidPressed(_:)))
    
    let buttonContainer = UIStackView()

    private(set) lazy var joinDefaultServerButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
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

    private(set) lazy var bottomButtonStackView: UIStackView = {
        let bottomButtonStackView = UIStackView(arrangedSubviews: [learnMoreButton, signInButton])
        bottomButtonStackView.axis = .horizontal
        bottomButtonStackView.distribution = .fill
        bottomButtonStackView.alignment = .center
        bottomButtonStackView.spacing = 16
        bottomButtonStackView.setContentHuggingPriority(.required, for: .vertical)

        return bottomButtonStackView
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

        mastodonLogo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mastodonLogo)
        
        NSLayoutConstraint.activate([
            mastodonLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            mastodonLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mastodonLogo.widthAnchor.constraint(equalToConstant: 300),
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
            joinDefaultServerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight)
        ])
        
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight)
        ])

        buttonContainer.addArrangedSubview(separatorView)

        signInButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            signInButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight)
        ])

        learnMoreButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            learnMoreButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight),
            bottomButtonStackView.heightAnchor.constraint(equalTo: learnMoreButton.heightAnchor),
        ])

        buttonContainer.addArrangedSubview(bottomButtonStackView)

        NSLayoutConstraint.activate([
            welcomeIllustrationView.topAnchor.constraint(equalTo: view.topAnchor),
            welcomeIllustrationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: welcomeIllustrationView.trailingAnchor),
            separatorView.centerYAnchor.constraint(equalTo: welcomeIllustrationView.bottomAnchor)
        ])

        joinDefaultServerButton.addTarget(self, action: #selector(joinDefaultServer(_:)), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(signUp(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)
        learnMoreButton.addTarget(self, action: #selector(learnMore(_:)), for: .touchUpInside)

        view.backgroundColor = Asset.Scene.Welcome.Illustration.backgroundGreen.color
        
        viewModel.$needsShowDismissEntry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsShowDismissEntry in
                guard let self = self else { return }
                self.navigationItem.leftBarButtonItem = needsShowDismissEntry ? self.dismissBarButtonItem : nil
            }
            .store(in: &disposeBag)

        setupIllustrationLayout()

        joinDefaultServerButton.configuration?.showsActivityIndicator = true
        joinDefaultServerButton.isEnabled = false
        joinDefaultServerButton.configuration?.title = nil

        viewModel.downloadDefaultServer { [weak self] in
            guard let selectedDefaultServer = self?.viewModel.randomDefaultServer else { return }

            DispatchQueue.main.async {
                self?.joinDefaultServerButton.configuration?.showsActivityIndicator = false
                self?.joinDefaultServerButton.isEnabled = true
                self?.joinDefaultServerButton.configuration?.attributedTitle = AttributedString(
                    L10n.Scene.Welcome.joinDefaultServer(selectedDefaultServer.domain),
                    attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
                )
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        view.layoutIfNeeded()
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
                bottom: 0,
                right: WelcomeViewController.actionButtonMargin
            )
        default:
            let margin = traitCollection.horizontalSizeClass == .regular ? WelcomeViewController.actionButtonMarginExtend : WelcomeViewController.actionButtonMargin
            buttonContainer.layoutMargins = UIEdgeInsets(
                top: 0,
                left: margin,
                bottom: 0,
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

        guard let server = viewModel.randomDefaultServer else { return }
        sender.configuration?.title = nil
        sender.isEnabled = false
        sender.configuration?.showsActivityIndicator = true

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
                case .failure(let error ):
                    guard let randomServer = self.viewModel.pickRandomDefaultServer() else { return }

                    viewModel.randomDefaultServer = randomServer

                    sender.isEnabled = true
                    sender.configuration?.showsActivityIndicator = false
                    sender.configuration?.attributedTitle = AttributedString(
                        L10n.Scene.Welcome.joinDefaultServer(randomServer.domain),
                        attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
                    )
                case .finished:
                    sender.isEnabled = true
                    sender.configuration?.showsActivityIndicator = false
                    sender.configuration?.attributedTitle = AttributedString(
                        L10n.Scene.Welcome.joinDefaultServer(server.domain),
                        attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
                    )
                }

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
