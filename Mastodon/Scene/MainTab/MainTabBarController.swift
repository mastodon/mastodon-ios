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
//        let tabBarAppearance = UITabBarAppearance()
//        tabBarAppearance.configureWithDefaultBackground()
//        tabBar.standardAppearance = tabBarAppearance
        
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
