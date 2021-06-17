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

class MainTabBarController: UITabBarController {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
        
    enum Tab: Int, CaseIterable {
        case home
        case search
        case notification
        case me
        
        var title: String {
            switch self {
            case .home:             return L10n.Common.Controls.Tabs.home
            case .search:           return L10n.Common.Controls.Tabs.search
            case .notification:     return L10n.Common.Controls.Tabs.notification
            case .me:               return L10n.Common.Controls.Tabs.profile
            }
        }
        
        var image: UIImage {
            switch self {
            case .home:             return UIImage(systemName: "house.fill")!
            case .search:           return UIImage(systemName: "magnifyingglass")!
            case .notification:     return UIImage(systemName: "bell.fill")!
            case .me:               return UIImage(systemName: "person.fill")!
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
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
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
        
        view.backgroundColor = .systemBackground
        
        let tabs = Tab.allCases
        let viewControllers: [UIViewController] = tabs.map { tab in
            let viewController = tab.viewController(context: context, coordinator: coordinator)
            viewController.tabBarItem.title = "" // set text to empty string for image only style (SDK failed to layout when set to nil)
            viewController.tabBarItem.image = tab.image
            viewController.tabBarItem.accessibilityLabel = tab.title
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        // TODO: custom accent color
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.selectionIndicatorTintColor = Asset.Colors.brandBlue.color
        tabBar.standardAppearance = tabBarAppearance
        
        
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
        context.statusPublishService
            .latestPublishingComposeViewModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] composeViewModel in
                guard let self = self else { return }
                guard let composeViewModel = composeViewModel else { return }
                guard let currentState = composeViewModel.publishStateMachine.currentState else { return }
                guard currentState is ComposeViewModel.PublishState.Fail else { return }
                
                let alertController = UIAlertController(title: L10n.Common.Alerts.PublishPostFailure.title, message: L10n.Common.Alerts.PublishPostFailure.message, preferredStyle: .alert)
                let discardAction = UIAlertAction(title: L10n.Common.Controls.Actions.discard, style: .destructive) { [weak self, weak composeViewModel] _ in
                    guard let self = self else { return }
                    guard let composeViewModel = composeViewModel else { return }
                    self.context.statusPublishService.remove(composeViewModel: composeViewModel)
                }
                alertController.addAction(discardAction)
                let retryAction = UIAlertAction(title: L10n.Common.Controls.Actions.tryAgain, style: .default) { [weak composeViewModel] _ in
                    guard let composeViewModel = composeViewModel else { return }
                    composeViewModel.publishStateMachine.enter(ComposeViewModel.PublishState.Publishing.self)
                }
                alertController.addAction(retryAction)
                self.present(alertController, animated: true, completion: nil)
            }
            .store(in: &disposeBag)
                
        // handle push notification. toggle entry when finish fetch latest notification
        context.notificationService.hasUnreadPushNotification
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasUnreadPushNotification in
                guard let self = self else { return }
                guard let notificationViewController = self.notificationViewController else { return }
                
                let image = hasUnreadPushNotification ? UIImage(systemName: "bell.badge.fill")! : UIImage(systemName: "bell.fill")!
                notificationViewController.tabBarItem.image = image
                notificationViewController.navigationController?.tabBarItem.image = image
            }
            .store(in: &disposeBag)
        
        context.notificationService.requestRevealNotificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notificationID in
                guard let self = self else { return }
                self.coordinator.switchToTabBar(tab: .notification)
                let threadViewModel = RemoteThreadViewModel(context: self.context, notificationID: notificationID)
                self.coordinator.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
            }
            .store(in: &disposeBag)
    }
        
}

extension MainTabBarController {

    var notificationViewController: NotificationViewController? {
        return viewController(of: NotificationViewController.self)
    }
    
}

// HIG: keyboard UX
// https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/keyboard/
extension MainTabBarController {
    
    var switchToTabKeyCommands: [UIKeyCommand] {
        var commands: [UIKeyCommand] = []
        for (i, tab) in Tab.allCases.enumerated() {
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
        let composeViewModel = ComposeViewModel(context: context, composeKind: .post)
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: nil, transition: .modal(animated: true, completion: nil))
    }
    
}
