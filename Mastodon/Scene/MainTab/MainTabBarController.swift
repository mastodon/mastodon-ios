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
        case publicTimeline
        
        var title: String {
            switch self {
            case .home:     return "Home"
            case .publicTimeline : return "public"
            }
        }
        
        var image: UIImage {
            switch self {
            case .home:     return UIImage(systemName: "house")!
            case .publicTimeline: return UIImage(systemName: "flame")!
            }
        }
        
        func viewController(context: AppContext, coordinator: SceneCoordinator) -> UIViewController {
            let viewController: UIViewController
            switch self {
            case .home:
                let _viewController = HomeViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .publicTimeline:
                let _viewController = PublicTimelineViewController()
                _viewController.viewModel = PublicTimelineViewModel(context: context)
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
                
        #if DEBUG
        // selectedIndex = 1
        #endif
    }
        
}
