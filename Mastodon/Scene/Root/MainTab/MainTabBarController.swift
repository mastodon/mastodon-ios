//
//  MainTabBarController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import UIKit
import Combine
import CoreDataStack
import SafariServices
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI

class MainTabBarController: UITabBarController {

    public var disposeBag = Set<AnyCancellable>()
    
    var authenticationBox: MastodonAuthenticationBox?
    
    private let largeContentViewerInteraction = UILargeContentViewerInteraction()
    
    static let avatarButtonSize = CGSize(width: 25, height: 25)
    let avatarButton = CircleAvatarButton()
    let accountSwitcherChevron = UIImageView(
        image: .chevronUpChevronDown?.withConfiguration(
            UIImage.SymbolConfiguration(weight: .bold)
        )
    )
    
    @Published var currentTab: Tab = .home

    let homeTimelineViewController: UIViewController
    let searchViewController: SearchViewController
    let composeViewController: UIViewController // placeholder
    let notificationViewController: UIViewController
    var meProfileViewController: UIViewController // placeholder

    private(set) var isReadyForWizardAvatarButton = false
    
    // output
    @Published var avatarURL: URL?
    
    // haptic feedback
    private let feedbackGenerator = FeedbackGenerator.shared
    
    init(
        authenticationBox: MastodonAuthenticationBox?
    ) {
        self.authenticationBox = authenticationBox

        homeTimelineViewController = TimelineListViewController(.home)
        homeTimelineViewController.configureTabBarItem(with: .home)

        searchViewController = SearchViewController()
        searchViewController.configureTabBarItem(with: .search)

        composeViewController = UIViewController()
        composeViewController.configureTabBarItem(with: .compose)
        
        notificationViewController = TimelineListViewController(.notifications(.everything))
        notificationViewController.configureTabBarItem(with: .notifications)


        meProfileViewController = UIViewController()
        meProfileViewController.configureTabBarItem(with: .me)

        if let authenticationBox {
            if let homeTimelineViewController = homeTimelineViewController as? HomeTimelineViewController {
                homeTimelineViewController.viewModel = HomeTimelineViewModel(authenticationBox: authenticationBox)
            }
            searchViewController.viewModel = SearchViewModel(authenticationBox: authenticationBox)
        }

        super.init(nibName: nil, bundle: nil)

        viewControllers = [homeTimelineViewController, searchViewController, composeViewController, notificationViewController, meProfileViewController].map { AdaptiveStatusBarStyleNavigationController(rootViewController: $0) }
        tabBar.addInteraction(largeContentViewerInteraction)
        
        for controller in viewControllers ?? [] {
            (controller as? UINavigationController)?.delegate = self
        }

        layoutAvatarButton()
        updateProfileTabA11y()
    }
    
    private func replace(_ oldVC: UIViewController, with newVC: UIViewController) {
        guard let navControllers = viewControllers as? [UINavigationController] else { return }
        guard let toReplace = navControllers.first(where: { $0.viewControllers[0] == oldVC }) else { return }
        toReplace.viewControllers = [newVC]
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension MainTabBarController {
    
    open override var childForStatusBarStyle: UIViewController? {
        return selectedViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        view.backgroundColor = .systemBackground

        // seealso: `ThemeService.apply(theme:)`
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        // hacky workaround for FB11986255 (Setting accessibilityUserInputLabels on a UITabBarItem has no effect)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            if let searchItem = self.tabBar.subviews.first(where: { $0.accessibilityLabel == Tab.search.title }) {
                searchItem.accessibilityUserInputLabels = Tab.search.inputLabels
            }
        }
        
        APIService.shared.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self, let coordinator = self.sceneCoordinator else { return }
                switch error {
                case .implicit:
                    break
                case .explicit:
                    let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    _ = coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
            }
            .store(in: &disposeBag)
        
        // handle post failure
        
        // handle push notification.
        // toggle entry when finish fetch latest notification
        Publishers.CombineLatest(
            NotificationService.shared.unreadNotificationCountDidUpdate,
            $currentTab
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] authentication, currentTab in
            guard let self else { return }

            let authentication = self.authenticationBox?.userAuthorization
            let hasUnreadPushNotification: Bool = authentication.flatMap { authentication in
                let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: authentication.accessToken)
                return count > 0
            } ?? false

            let image: UIImage
            if hasUnreadPushNotification {
                let imageConfiguration = UIImage.SymbolConfiguration(paletteColors: [.red, SystemTheme.tabBarItemNormalIconColor])
                image = UIImage(systemName: "bell.badge", withConfiguration: imageConfiguration)!
            } else {
                image = Tab.notifications.image
            }

            notificationViewController.tabBarItem.image = image.imageWithoutBaseline()
            notificationViewController.navigationController?.tabBarItem.image = image.imageWithoutBaseline()
        }
        .store(in: &disposeBag)
        
        $currentTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentTab in
                guard let self else { return }
                
                if currentTab == .me {
                    guard let authBox = authenticationBox, let myAccount = authBox.cachedAccount else { return }
                    guard !(meProfileViewController is ProfileViewController) else { return }
                    let oldMe = meProfileViewController
                    let updatedProfile = ProfileViewController(.me(myAccount), authenticationBox: authBox)
                    meProfileViewController = updatedProfile
                    updatedProfile.configureTabBarItem(with: .me)
                    self.replace(oldMe, with: updatedProfile)
                    if let domain = myAccount.domain ?? myAccount.domainFromAcct {
                        self.avatarURL =  myAccount.avatarImageURLWithFallback(domain: domain)
                    } else {
                        self.avatarURL = myAccount.avatarImageURL()
                    }
                    
                    self.avatarButton.removeFromSuperview()
                    self.layoutAvatarButton()
                }
            }
            .store(in: &disposeBag)

        $avatarURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] avatarURL in
                guard let self else { return }
                self.avatarButton.avatarImageView.setImage(
                    url: avatarURL,
                    placeholder: .placeholder(color: .systemFill),
                    scaleToSize: MainTabBarController.avatarButtonSize
                )
            }
            .store(in: &disposeBag)
        
        AuthenticationServiceProvider.shared.updateActiveUserAccountPublisher
            .sink { [weak self] in
                self?.updateUserAccount()
            }
            .store(in: &self.disposeBag)
        
        AuthenticationServiceProvider.shared.currentActiveUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeUser in
                if let domain = activeUser?.domain {
                    self?.avatarURL = activeUser?.cachedAccount?.avatarImageURLWithFallback(domain: domain)
                } else {
                    self?.avatarURL = activeUser?.cachedAccount?.avatarImageURL()
                }
            }
            .store(in: &disposeBag)

        NotificationCenter.default.publisher(for: .userFetched)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self,
                      let authenticationBox,
                      let account = authenticationBox.cachedAccount else { return }

                self.avatarURL = account.avatarImageURL()

                // a11y
                let _profileTabItem = self.tabBar.items?.first { item in item.tag == Tab.me.tag }
                guard let profileTabItem = _profileTabItem else { return }
                profileTabItem.accessibilityHint = L10n.Scene.AccountList.tabBarHint(account.displayNameWithFallback)
            }
            .store(in: &disposeBag)
        
        let tabBarLongPressGestureRecognizer = UILongPressGestureRecognizer()
        tabBarLongPressGestureRecognizer.addTarget(self, action: #selector(MainTabBarController.tabBarLongPressGestureRecognizerHandler(_:)))
        tabBarLongPressGestureRecognizer.delegate = self
        tabBar.addGestureRecognizer(tabBarLongPressGestureRecognizer)
        
        let tabBarDoubleTapGestureRecognizer = UITapGestureRecognizer()
        tabBarDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        tabBarDoubleTapGestureRecognizer.addTarget(self, action: #selector(MainTabBarController.tabBarDoubleTapGestureRecognizerHandler(_:)))
        tabBarDoubleTapGestureRecognizer.delaysTouchesEnded = false
        tabBar.addGestureRecognizer(tabBarDoubleTapGestureRecognizer)
        
        self.isReadyForWizardAvatarButton = authenticationBox != nil
        
        $currentTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tab in
                guard let self else { return }
                self.updateAvatarButtonAppearance()
            }
            .store(in: &disposeBag)

        updateTabBarDisplay()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateTabBarDisplay()
        updateAvatarButtonAppearance()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portraitOnPhone
    }
}

extension MainTabBarController {
    func updateProfileTabA11y() {
        guard let authBox = authenticationBox, let account = authBox.cachedAccount else { return }
        let _profileTabItem = self.tabBar.items?.first { item in item.tag == Tab.me.tag }
        guard let profileTabItem = _profileTabItem else { return }
        profileTabItem.accessibilityHint = L10n.Scene.AccountList.tabBarHint(account.displayNameWithFallback)
    }
}

extension MainTabBarController {
    
    @objc private func composeButtonDidPressed(_ sender: Any) {

        feedbackGenerator.generate(.impact(.medium))
        guard let authenticationBox else { return }
        let composeViewModel = ComposeViewModel(
            authenticationBox: authenticationBox,
            composeContext: .composeStatus(quoting: nil),
            destination: .topLevel
        )
        _ = self.sceneCoordinator?.present(scene: .compose(viewModel: composeViewModel), transition: .modal(animated: true, completion: nil))
    }
    
    private func touchedTab(by sender: UIGestureRecognizer) -> Tab? {
        var _tab: Tab?
        let location = sender.location(in: tabBar)
        for item in tabBar.items ?? [] {
            guard let tab = Tab(rawValue: item.tag) else { continue }
            guard let view = item.value(forKey: "view") as? UIView else { continue }
            guard view.frame.contains(location) else { continue}

            _tab = tab
            break
        }

        return _tab
    }
    
    @objc private func tabBarDoubleTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        guard let tab = touchedTab(by: sender) else { return }

        switch tab {
        case .search:
            assert(Thread.isMainThread)
            // double tapping search tab opens the search bar without additional taps
            searchViewController.searchBar.becomeFirstResponder()
        default:
            break
        }
    }
    
    @objc private func tabBarLongPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard let tab = touchedTab(by: sender) else { return }

        switch tab {
        case .me:
            guard let authenticationBox else { return }
            let accountListViewModel = AccountListViewModel(authenticationBox: authenticationBox)
            _ = self.sceneCoordinator?.present(scene: .accountList(viewModel: accountListViewModel), from: self, transition: .formSheet(nil))
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
        default:
            tabBar.isHidden = true
            if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
                self.isTabBarHidden = true
            }
        }
    }

    private func layoutAvatarButton() {
        guard avatarButton.superview == nil else { return }
        
        guard let profileTabItem = meProfileViewController.tabBarItem else { return }
        guard let view = profileTabItem.value(forKey: "view") as? UIView else {
            return
        }
        
        let _anchorImageView = view.subviews.first { subview in subview is UIImageView } as? UIImageView
        guard let anchorImageView = _anchorImageView else {
            assertionFailure()
            return
        }
        anchorImageView.alpha = 0
        
        accountSwitcherChevron.removeFromSuperview()
        accountSwitcherChevron.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(accountSwitcherChevron)
        
        self.avatarButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.avatarButton)
        NSLayoutConstraint.activate([
            self.avatarButton.centerXAnchor.constraint(equalTo: anchorImageView.centerXAnchor),
            self.avatarButton.centerYAnchor.constraint(equalTo: anchorImageView.centerYAnchor),
            self.avatarButton.widthAnchor.constraint(equalToConstant: MainTabBarController.avatarButtonSize.width).priority(.required - 1),
            self.avatarButton.heightAnchor.constraint(equalToConstant: MainTabBarController.avatarButtonSize.height).priority(.required - 1),
            accountSwitcherChevron.widthAnchor.constraint(equalToConstant: 10),
            accountSwitcherChevron.heightAnchor.constraint(equalToConstant: 18),
            accountSwitcherChevron.leadingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: 8),
            accountSwitcherChevron.centerYAnchor.constraint(equalTo: avatarButton.centerYAnchor)
        ])
        self.avatarButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        self.avatarButton.setContentHuggingPriority(.required - 1, for: .vertical)
        self.avatarButton.isUserInteractionEnabled = false
    }
    
    private func updateAvatarButtonAppearance() {
        if currentTab == .me {
            accountSwitcherChevron.tintColor = Asset.Colors.Brand.blurple.color
            avatarButton.borderColor = Asset.Colors.Brand.blurple.color
        } else {
            accountSwitcherChevron.tintColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
            avatarButton.borderColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
        }

        avatarButton.setNeedsLayout()
    }
    
    private func updateUserAccount() {
        guard let authenticationBox else { return }
        
        Task { @MainActor in
            let profileResponse = try await APIService.shared.accountInfo(authenticationBox)
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let tab = Tab(rawValue: viewController.tabBarItem.tag), tab == .compose {
            composeButtonDidPressed(tabBarController)
            return false
        }
        
        // Different tab has been selected, send haptic feedback
        if viewController.tabBarItem.tag != tabBarController.selectedIndex {
            feedbackGenerator.generate(.impact(.medium))
        }

        // Assert index is as same as the tab rawValue. This check needs to be done `shouldSelect`
        // because the nav controller has already popped in `didSelect`.
        if currentTab.rawValue == viewController.tabBarItem.tag,
           let navigationController = viewController as? UINavigationController,
           navigationController.viewControllers.count == 1,
           let scrollViewContainer = navigationController.topViewController as? ScrollViewContainer  {
            scrollViewContainer.scrollToTop(animated: true)
        }

        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let tab = Tab(rawValue: viewController.tabBarItem.tag) {
            currentTab = tab
        }
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
            .notifications,
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
            if SettingService.shared.currentSetting.value != nil {
                commands.append(openSettingsKeyCommand)
            }
        }

        return commands
    }
    
    @objc private func switchToTabKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? Int,
              let tab = Tab(rawValue: rawValue) else { return }

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
        guard let authenticationBox else { return }
        let favoriteViewModel = FavoriteViewModel(authenticationBox: authenticationBox)
        _ = self.sceneCoordinator?.present(scene: .favorite(viewModel: favoriteViewModel), from: nil, transition: .show)
    }
    
    @objc private func openSettingsKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let setting = SettingService.shared.currentSetting.value else { return }

        _ = self.sceneCoordinator?.present(scene: .settings(setting: setting), from: self, transition: .none)
    }
    
    @objc private func composeNewPostKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let authenticationBox else { return }
        let composeViewModel = ComposeViewModel(
            authenticationBox: authenticationBox,
            composeContext: .composeStatus(quoting: nil),
            destination: .topLevel
        )
        _ = self.sceneCoordinator?.present(scene: .compose(viewModel: composeViewModel), from: nil, transition: .modal(animated: true, completion: nil))
    }
    
}

extension MainTabBarController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension MainTabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        // disable animations when transitioning to/from the profile view controller, since it has a transparent background on the nav bar which makes the transition to standard nav bars look broken
        if viewController is ProfileViewController || navigationController.topViewController is ProfileViewController {
            if let coordinator = navigationController.topViewController?.transitionCoordinator {
                let transparentAppearance = UINavigationBarAppearance()
                transparentAppearance.configureWithTransparentBackground()
                navigationController.navigationBar.standardAppearance = transparentAppearance
                navigationController.navigationBar.compactAppearance = transparentAppearance
                navigationController.navigationBar.scrollEdgeAppearance = transparentAppearance
                coordinator.animate(alongsideTransition: nil) { _ in
                    navigationController.setNeedsStatusBarAppearanceUpdate()
                }
            }
        } else {
            let nonTransparentAppearance = UINavigationBarAppearance()
            nonTransparentAppearance.configureWithDefaultBackground()
            navigationController.navigationBar.standardAppearance = nonTransparentAppearance
            navigationController.navigationBar.compactAppearance = nonTransparentAppearance
            navigationController.navigationBar.scrollEdgeAppearance = nonTransparentAppearance
            if let coordinator = navigationController.topViewController?.transitionCoordinator {
                coordinator.animate(alongsideTransition: nil) { _ in
                    navigationController.setNeedsStatusBarAppearanceUpdate()
                }
            } else {
                navigationController.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}
