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
            case .home:             return "Home"
            case .search:           return "Search"
            case .notification:     return "Notification"
            case .me:               return "Me"
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
                viewController = _viewController
            }
            viewController.title = self.title
            return UINavigationController(rootViewController: viewController)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let tabs = Tab.allCases
        let viewControllers: [UIViewController] = tabs.map { tab in
            let viewController = tab.viewController(context: context, coordinator: coordinator)
            viewController.tabBarItem.title = "" // set text to empty string for image only style (SDK failed to layout when set to nil)
            viewController.tabBarItem.image = tab.image
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        // TODO: custom accent color
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
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
        
        context.authenticationService.activeMastodonAuthenticationBox
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeMastodonAuthenticationBox in
                guard let self = self else { return }
                guard let activeMastodonAuthenticationBox = activeMastodonAuthenticationBox else { return }
                let domain = activeMastodonAuthenticationBox.domain
                
                // trigger dequeue to preload emojis
                _ = self.context.emojiService.dequeueCustomEmojiViewModel(for: domain)
            }
            .store(in: &disposeBag)
                
        #if DEBUG
        // selectedIndex = 1
        #endif
    }
        
}
