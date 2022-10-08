//
//  MainTabBarController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import os.log
import UIKit
import Combine
import SafariServices
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI

class MainTabBarController: UITabBarController {

    let logger = Logger(subsystem: "MainTabBarController", category: "UI")
    
    public var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
    
    var authContext: AuthContext?
    
    let composeButttonShadowBackgroundContainer = ShadowBackgroundContainer()
    let composeButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Label.primary.color), for: .normal)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Label.primary.color.withAlphaComponent(0.8)), for: .highlighted)
        button.tintColor = Asset.Colors.Label.primaryReverse.color
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.masksToBounds = true
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 8
        return button
    }()
    
    static let avatarButtonSize = CGSize(width: 25, height: 25)
    let avatarButton = CircleAvatarButton()
    
    @Published var currentTab: Tab = .home
        
    enum Tab: Int, CaseIterable {
        case home
        case search
        case compose
        case notification
        case me

        var tag: Int {
            return rawValue
        }
        
        var title: String {
            switch self {
            case .home:             return L10n.Common.Controls.Tabs.home
            case .search:           return L10n.Common.Controls.Tabs.search
            case .compose:          return L10n.Common.Controls.Actions.compose
            case .notification:     return L10n.Common.Controls.Tabs.notification
            case .me:               return L10n.Common.Controls.Tabs.profile
            }
        }
        
        var image: UIImage {
            switch self {
            case .home:             return Asset.ObjectsAndTools.house.image.withRenderingMode(.alwaysTemplate)
            case .search:           return Asset.ObjectsAndTools.magnifyingglass.image.withRenderingMode(.alwaysTemplate)
            case .compose:          return Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate)
            case .notification:     return Asset.ObjectsAndTools.bell.image.withRenderingMode(.alwaysTemplate)
            case .me:               return UIImage(systemName: "person")!
            }
        }
        
        var selectedImage: UIImage {
            switch self {
            case .home:             return Asset.ObjectsAndTools.houseFill.image.withRenderingMode(.alwaysTemplate)
            case .search:           return Asset.ObjectsAndTools.magnifyingglassFill.image.withRenderingMode(.alwaysTemplate)
            case .compose:          return Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate)
            case .notification:     return Asset.ObjectsAndTools.bellFill.image.withRenderingMode(.alwaysTemplate)
            case .me:               return UIImage(systemName: "person.fill")!
            }
        }

        var largeImage: UIImage {
            switch self {
            case .home:             return Asset.ObjectsAndTools.house.image.withRenderingMode(.alwaysTemplate).resized(size: CGSize(width: 80, height: 80))
            case .search:           return Asset.ObjectsAndTools.magnifyingglass.image.withRenderingMode(.alwaysTemplate).resized(size: CGSize(width: 80, height: 80))
            case .compose:          return Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate).resized(size: CGSize(width: 80, height: 80))
            case .notification:     return Asset.ObjectsAndTools.bell.image.withRenderingMode(.alwaysTemplate).resized(size: CGSize(width: 80, height: 80))
            case .me:               return UIImage(systemName: "person", withConfiguration: UIImage.SymbolConfiguration(pointSize: 80))!
            }
        }
        
        var sidebarImage: UIImage {
            switch self {
            case .home:             return Asset.ObjectsAndTools.house.image.withRenderingMode(.alwaysTemplate)
            case .search:           return Asset.ObjectsAndTools.magnifyingglass.image.withRenderingMode(.alwaysTemplate)
            case .compose:          return Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate)
            case .notification:     return Asset.ObjectsAndTools.bell.image.withRenderingMode(.alwaysTemplate)
            case .me:               return UIImage(systemName: "person")!
            }
        }
        
        func viewController(context: AppContext, coordinator: SceneCoordinator) -> UIViewController {
            let viewController: UIViewController
            switch self {
            case .home:
                let _viewController = HomeTimelineViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .search:
                let _viewController = SearchViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .compose:
                viewController = UIViewController()
            case .notification:
                let _viewController = NotificationViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .me:
                let _viewController = ProfileViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                _viewController.viewModel = MeProfileViewModel(context: context)
                viewController = _viewController
            }
            viewController.title = self.title
            return AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
        }
    }
    
    var _viewControllers: [UIViewController] = []
    
    private(set) var isReadyForWizardAvatarButton = false
    
    // output
    var avatarURLObserver: AnyCancellable?
    @Published var avatarURL: URL?

    init(
        context: AppContext,
        coordinator: SceneCoordinator,
        authContext: AuthContext?
    ) {
        self.context = context
        self.coordinator = coordinator
        self.authContext = authContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension MainTabBarController {
    
    open override var childForStatusBarStyle: UIViewController? {
        return selectedViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        view.backgroundColor = ThemeService.shared.currentTheme.value.systemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.tabBarBackgroundColor
            }
            .store(in: &disposeBag)

        // seealso: `ThemeService.apply(theme:)`
        let tabs = Tab.allCases
        let viewControllers: [UIViewController] = tabs.map { tab in
            let viewController = tab.viewController(context: context, coordinator: coordinator)
            viewController.tabBarItem.tag = tab.tag
            viewController.tabBarItem.title = tab.title     // needs for acessiblity large content label
            viewController.tabBarItem.image = tab.image.imageWithoutBaseline()
            viewController.tabBarItem.selectedImage = tab.selectedImage.imageWithoutBaseline()
            viewController.tabBarItem.largeContentSizeImage = tab.largeImage.imageWithoutBaseline()
            viewController.tabBarItem.accessibilityLabel = tab.title
            viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            
            switch tab {
            case .compose:
                viewController.tabBarItem.isEnabled = false
            default:
                break
            }
            
            return viewController
        }
        _viewControllers = viewControllers
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        context.apiService.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self, let coordinator = self.coordinator else { return }
                switch error {
                case .implicit:
                    break
                case .explicit:
                    let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
            }
            .store(in: &disposeBag)
        
        // handle post failure
        // FIXME: refacotr
//        context.statusPublishService
//            .latestPublishingComposeViewModel
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] composeViewModel in
//                guard let self = self else { return }
//                guard let composeViewModel = composeViewModel else { return }
//                guard let currentState = composeViewModel.publishStateMachine.currentState else { return }
//                guard currentState is ComposeViewModel.PublishState.Fail else { return }
//
//                let alertController = UIAlertController(title: L10n.Common.Alerts.PublishPostFailure.title, message: L10n.Common.Alerts.PublishPostFailure.message, preferredStyle: .alert)
//                let discardAction = UIAlertAction(title: L10n.Common.Controls.Actions.discard, style: .destructive) { [weak self, weak composeViewModel] _ in
//                    guard let self = self else { return }
//                    guard let composeViewModel = composeViewModel else { return }
//                    self.context.statusPublishService.remove(composeViewModel: composeViewModel)
//                }
//                alertController.addAction(discardAction)
//                let retryAction = UIAlertAction(title: L10n.Common.Controls.Actions.tryAgain, style: .default) { [weak composeViewModel] _ in
//                    guard let composeViewModel = composeViewModel else { return }
//                    composeViewModel.publishStateMachine.enter(ComposeViewModel.PublishState.Publishing.self)
//                }
//                alertController.addAction(retryAction)
//                self.present(alertController, animated: true, completion: nil)
//            }
//            .store(in: &disposeBag)
                
        // handle push notification.
        // toggle entry when finish fetch latest notification
        Publishers.CombineLatest3(
            context.authenticationService.activeMastodonAuthentication,
            context.notificationService.unreadNotificationCountDidUpdate,
            $currentTab
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] authentication, _, currentTab in
            guard let self = self else { return }
            guard let notificationViewController = self.notificationViewController else { return }
            
            let hasUnreadPushNotification: Bool = authentication.flatMap { authentication in
                let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: authentication.userAccessToken)
                return count > 0
            } ?? false
            
            let image: UIImage = {
                if currentTab == .notification {
                    return hasUnreadPushNotification ? Asset.ObjectsAndTools.bellBadgeFill.image.withRenderingMode(.alwaysTemplate) : Asset.ObjectsAndTools.bellFill.image.withRenderingMode(.alwaysTemplate)
                } else {
                    return hasUnreadPushNotification ? Asset.ObjectsAndTools.bellBadge.image.withRenderingMode(.alwaysTemplate) : Asset.ObjectsAndTools.bell.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            notificationViewController.tabBarItem.image = image.imageWithoutBaseline()
            notificationViewController.navigationController?.tabBarItem.image = image.imageWithoutBaseline()
        }
        .store(in: &disposeBag)
        
        layoutComposeButton()
        layoutAvatarButton()
        
        $avatarURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] avatarURL in
                guard let self = self else { return }
                self.avatarButton.avatarImageView.setImage(
                    url: avatarURL,
                    placeholder: .placeholder(color: .systemFill),
                    scaleToSize: MainTabBarController.avatarButtonSize
                )
            }
            .store(in: &disposeBag)
        context.authenticationService.activeMastodonAuthentication
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeMastodonAuthentication in
                guard let self = self else { return }
                
                if let user = activeMastodonAuthentication?.user {
                    self.avatarURLObserver = user.publisher(for: \.avatar)
                        .sink { [weak self, weak user] _ in
                            guard let self = self else { return }
                            guard let user = user else { return }
                            guard user.managedObjectContext != nil else { return }
                            self.avatarURL = user.avatarImageURL()
                        }
                } else {
                    self.avatarURLObserver = nil
                }
                
                // a11y
                let _profileTabItem = self.tabBar.items?.first { item in item.tag == Tab.me.tag }
                guard let profileTabItem = _profileTabItem else { return }
                
                let currentUserDisplayName = activeMastodonAuthentication?.user.displayNameWithFallback ?? "no user"
                profileTabItem.accessibilityHint = L10n.Scene.AccountList.tabBarHint(currentUserDisplayName)
            }
            .store(in: &disposeBag)

        let tabBarLongPressGestureRecognizer = UILongPressGestureRecognizer()
        tabBarLongPressGestureRecognizer.addTarget(self, action: #selector(MainTabBarController.tabBarLongPressGestureRecognizerHandler(_:)))
        tabBar.addGestureRecognizer(tabBarLongPressGestureRecognizer)
        
        context.authenticationService.activeMastodonAuthenticationBox
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationBox in
                guard let self = self else { return }
                self.isReadyForWizardAvatarButton = authenticationBox != nil
            }
            .store(in: &disposeBag)
        
        $currentTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tab in
                guard let self = self else { return }
                self.updateAvatarButtonAppearance()
            }
            .store(in: &disposeBag)
        
        updateTabBarDisplay()
        
        composeButton.addTarget(self, action: #selector(MainTabBarController.composeButtonDidPressed(_:)), for: .touchUpInside)
        
        #if DEBUG
        // Debug Register viewController
        // Task { @MainActor in
        //     let _homeTimelineViewController = viewControllers
        //         .compactMap { $0 as? UINavigationController }
        //         .compactMap { $0.topViewController }
        //         .compactMap { $0 as? HomeTimelineViewController }
        //         .first
        //     try await _homeTimelineViewController?.showRegisterController()
        // }   // end Task
        #endif
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateTabBarDisplay()
        updateComposeButtonAppearance()
        updateAvatarButtonAppearance()
    }

}

extension MainTabBarController {
    
    @objc private func composeButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        let composeViewModel = ComposeViewModel(
            context: context,
            composeKind: .post,
            authenticationBox: authenticationBox
        )
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: nil, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func tabBarLongPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }

        var _tab: Tab?
        let location = sender.location(in: tabBar)
        for item in tabBar.items ?? [] {
            guard let tab = Tab(rawValue: item.tag) else { continue }
            guard let view = item.value(forKey: "view") as? UIView else { continue }
            guard view.frame.contains(location) else { continue}

            _tab = tab
            break
        }

        guard let tab = _tab else { return }
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): long press \(tab.title) tab")

        switch tab {
        case .me:
            coordinator.present(scene: .accountList, from: self, transition: .panModal)
        default:
            break
        }
    }
}

extension MainTabBarController {
    
    private func updateTabBarDisplay() {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            tabBar.isHidden = false
            composeButttonShadowBackgroundContainer.isHidden = false
        default:
            tabBar.isHidden = true
            composeButttonShadowBackgroundContainer.isHidden = true
        }
    }
    
    private func layoutComposeButton() {
        guard composeButton.superview == nil else { return }

        let _composeTabItem = self.tabBar.items?.first { item in item.tag == Tab.compose.tag }
        guard let composeTabItem = _composeTabItem else { return }
        guard let view = composeTabItem.value(forKey: "view") as? UIView else {
            return
        }
        
        let _anchorImageView = view.subviews.first { subview in subview is UIImageView } as? UIImageView
        guard let anchorImageView = _anchorImageView else {
            assertionFailure()
            return
        }
        anchorImageView.alpha = 0
        
        composeButttonShadowBackgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(composeButttonShadowBackgroundContainer)   // add to tabBar will crash on iPad when size class changing
        NSLayoutConstraint.activate([
            composeButttonShadowBackgroundContainer.centerXAnchor.constraint(equalTo: anchorImageView.centerXAnchor),
            composeButttonShadowBackgroundContainer.centerYAnchor.constraint(equalTo: anchorImageView.centerYAnchor),
        ])
        composeButttonShadowBackgroundContainer.cornerRadius = composeButton.layer.cornerRadius
        
        composeButton.translatesAutoresizingMaskIntoConstraints = false
        composeButttonShadowBackgroundContainer.addSubview(composeButton)
        NSLayoutConstraint.activate([
            composeButton.topAnchor.constraint(equalTo: composeButttonShadowBackgroundContainer.topAnchor),
            composeButton.leadingAnchor.constraint(equalTo: composeButttonShadowBackgroundContainer.leadingAnchor),
            composeButton.trailingAnchor.constraint(equalTo: composeButttonShadowBackgroundContainer.trailingAnchor),
            composeButton.bottomAnchor.constraint(equalTo: composeButttonShadowBackgroundContainer.bottomAnchor),
        ])
        composeButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        composeButton.setContentHuggingPriority(.required - 1, for: .vertical)
    }
    
    private func updateComposeButtonAppearance() {
        composeButton.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Label.primary.color), for: .normal)
        composeButton.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Label.primary.color.withAlphaComponent(0.8)), for: .highlighted)
    }
    
    private func layoutAvatarButton() {
        guard avatarButton.superview == nil else { return }
        
        let _profileTabItem = self.tabBar.items?.first { item in item.tag == Tab.me.tag }
        guard let profileTabItem = _profileTabItem else { return }
        guard let view = profileTabItem.value(forKey: "view") as? UIView else {
            return
        }
        
        let _anchorImageView = view.subviews.first { subview in subview is UIImageView } as? UIImageView
        guard let anchorImageView = _anchorImageView else {
            assertionFailure()
            return
        }
        anchorImageView.alpha = 0
        
        self.avatarButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.avatarButton)
        NSLayoutConstraint.activate([
            self.avatarButton.centerXAnchor.constraint(equalTo: anchorImageView.centerXAnchor),
            self.avatarButton.centerYAnchor.constraint(equalTo: anchorImageView.centerYAnchor),
            self.avatarButton.widthAnchor.constraint(equalToConstant: MainTabBarController.avatarButtonSize.width).priority(.required - 1),
            self.avatarButton.heightAnchor.constraint(equalToConstant: MainTabBarController.avatarButtonSize.height).priority(.required - 1),
        ])
        self.avatarButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        self.avatarButton.setContentHuggingPriority(.required - 1, for: .vertical)
        self.avatarButton.isUserInteractionEnabled = false
    }
    
    private func updateAvatarButtonAppearance() {
        avatarButton.borderColor = currentTab == .me ? .label : .systemFill
        avatarButton.setNeedsLayout()
    }
    
}

extension MainTabBarController {

    var notificationViewController: NotificationViewController? {
        return viewController(of: NotificationViewController.self)
    }
    
    var searchViewController: SearchViewController? {
        return viewController(of: SearchViewController.self)
    }
    
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select %s", ((#file as NSString).lastPathComponent), #line, #function, viewController.debugDescription)
        defer {
            if let tab = Tab(rawValue: viewController.tabBarItem.tag) {
                currentTab = tab
            }
        }
        // assert index is as same as the tab rawValue
        guard currentTab.rawValue == tabBarController.selectedIndex,
              let navigationController = viewController as? UINavigationController,
              navigationController.viewControllers.count == 1,
              let scrollViewContainer = navigationController.topViewController as? ScrollViewContainer else {
            return
        }

        scrollViewContainer.scrollToTop(animated: true)
    }
}

// MARK: - WizardViewControllerDelegate
extension MainTabBarController: WizardViewControllerDelegate {
    func readyToLayoutItem(_ wizardViewController: WizardViewController, item: WizardViewController.Item) -> Bool {
        switch item {
        case .multipleAccountSwitch:
            return isReadyForWizardAvatarButton
        }
    }
    
    func layoutSpotlight(_ wizardViewController: WizardViewController, item: WizardViewController.Item) -> UIBezierPath {
        switch item {
        case .multipleAccountSwitch:
            guard let avatarButtonFrameInView = avatarButtonFrameInWizardView(wizardView: wizardViewController.view) else {
                return UIBezierPath()
            }
            return UIBezierPath(ovalIn: avatarButtonFrameInView)
        }
    }
    
    func layoutWizardCard(_ wizardViewController: WizardViewController, item: WizardViewController.Item) {
        switch item {
        case .multipleAccountSwitch:
            guard let avatarButtonFrameInView = avatarButtonFrameInWizardView(wizardView: wizardViewController.view) else {
                return
            }
            let anchorView = UIView()
            anchorView.frame = avatarButtonFrameInView
            wizardViewController.backgroundView.addSubview(anchorView)
            
            let wizardCardView = WizardCardView()
            wizardCardView.arrowRectCorner = view.traitCollection.layoutDirection == .leftToRight ? .bottomRight : .bottomLeft
            wizardCardView.titleLabel.text = item.title
            wizardCardView.descriptionLabel.text = item.description
            
            wizardCardView.translatesAutoresizingMaskIntoConstraints = false
            wizardViewController.backgroundView.addSubview(wizardCardView)
            NSLayoutConstraint.activate([
                anchorView.topAnchor.constraint(equalTo: wizardCardView.bottomAnchor, constant: 13), // 13pt spacing
                wizardCardView.trailingAnchor.constraint(equalTo: anchorView.centerXAnchor),
                wizardCardView.widthAnchor.constraint(equalTo: wizardViewController.view.widthAnchor, multiplier: 2.0/3.0).priority(.required - 1),
            ])
            wizardCardView.setContentHuggingPriority(.defaultLow, for: .vertical)
        }
    }
    
    private func avatarButtonFrameInWizardView(wizardView: UIView) -> CGRect? {
        guard let superview = avatarButton.superview else {
            assertionFailure()
            return nil
        }
        return superview.convert(avatarButton.frame, to: wizardView)
    }
}

// HIG: keyboard UX
// https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/keyboard/
extension MainTabBarController {
    
    var switchToTabKeyCommands: [UIKeyCommand] {
        var commands: [UIKeyCommand] = []
        let tabs: [Tab] = [
            .home,
            .search,
            .notification,
            .me
        ]
        for (i, tab) in tabs.enumerated() {
            let title = L10n.Common.Controls.Keyboard.Common.switchToTab(tab.title)
            let input = String(i + 1)
            let command = UIKeyCommand(
                title: title,
                image: nil,
                action: #selector(MainTabBarController.switchToTabKeyCommandHandler(_:)),
                input: input,
                modifierFlags: .command,
                propertyList: tab.rawValue,
                alternates: [],
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            )
            commands.append(command)
        }
        return commands
    }
    
    var showFavoritesKeyCommand: UIKeyCommand {
        UIKeyCommand(
            title: L10n.Common.Controls.Keyboard.Common.showFavorites,
            image: nil,
            action: #selector(MainTabBarController.showFavoritesKeyCommandHandler(_:)),
            input: "f",
            modifierFlags: .command,
            propertyList: nil,
            alternates: [],
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        )
    }
    
    var openSettingsKeyCommand: UIKeyCommand {
        UIKeyCommand(
            title: L10n.Common.Controls.Keyboard.Common.openSettings,
            image: nil,
            action: #selector(MainTabBarController.openSettingsKeyCommandHandler(_:)),
            input: ",",
            modifierFlags: .command,
            propertyList: nil,
            alternates: [],
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        )
    }
    
    var composeNewPostKeyCommand: UIKeyCommand {
        UIKeyCommand(
            title: L10n.Common.Controls.Keyboard.Common.composeNewPost,
            image: nil,
            action: #selector(MainTabBarController.composeNewPostKeyCommandHandler(_:)),
            input: "n",
            modifierFlags: .command,
            propertyList: nil,
            alternates: [],
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        )
    }
    
    override var keyCommands: [UIKeyCommand]? {
        guard let topMost = self.topMost else {
            return []
        }
        
        var commands: [UIKeyCommand] = []
        
        if topMost.isModal {
            
        } else {
            // switch tabs
            commands.append(contentsOf: switchToTabKeyCommands)
            
            // show compose
            if !(self.topMost is ComposeViewController) {
                commands.append(composeNewPostKeyCommand)
            }
            
            // show favorites
            if !(self.topMost is FavoriteViewController) {
                commands.append(showFavoritesKeyCommand)
            }
            
            // open settings
            if context.settingService.currentSetting.value != nil {
                commands.append(openSettingsKeyCommand)
            }
        }

        return commands
    }
    
    @objc private func switchToTabKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? Int,
              let tab = Tab(rawValue: rawValue) else { return }
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, tab.title)
        
        guard let index = Tab.allCases.firstIndex(of: tab) else { return }
        let previousTab = Tab(rawValue: selectedIndex)
        selectedIndex = index
        if let tab = Tab(rawValue: index) {
            currentTab = tab
        }

        if let previousTab = previousTab {
            switch (tab, previousTab) {
            case (.home, .home):
                guard let navigationController = topMost?.navigationController else { return }
                if navigationController.viewControllers.count > 1 {
                    // pop to top when previous tab position already is home
                    navigationController.popToRootViewController(animated: true)
                } else if let homeTimelineViewController = topMost as? HomeTimelineViewController {
                    // trigger scrollToTop if topMost is home timeline
                    homeTimelineViewController.scrollToTop(animated: true)
                }
            default:
                break
            }
        }
    }
    
    @objc private func showFavoritesKeyCommandHandler(_ sender: UIKeyCommand) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let favoriteViewModel = FavoriteViewModel(context: context)
        coordinator.present(scene: .favorite(viewModel: favoriteViewModel), from: nil, transition: .show)
    }
    
    @objc private func openSettingsKeyCommandHandler(_ sender: UIKeyCommand) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let setting = context.settingService.currentSetting.value else { return }
        let settingsViewModel = SettingsViewModel(context: context, setting: setting)
        coordinator.present(scene: .settings(viewModel: settingsViewModel), from: nil, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func composeNewPostKeyCommandHandler(_ sender: UIKeyCommand) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        let composeViewModel = ComposeViewModel(
            context: context,
            composeKind: .post,
            authenticationBox: authenticationBox
        )
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: nil, transition: .modal(animated: true, completion: nil))
    }
    
}
