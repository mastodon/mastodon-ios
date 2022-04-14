//
//  DiscoveryViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import UIKit
import Tabman
import Pageboy

final class DiscoveryViewModel {
    
    // input
    let context: AppContext
    let discoveryPostsViewController: DiscoveryPostsViewController
    let discoveryHashtagsViewController: DiscoveryHashtagsViewController
    let discoveryNewsViewController: DiscoveryNewsViewController
    let discoveryForYouViewController: DiscoveryForYouViewController
    
    // output
    let barItems: [TMBarItemable] = {
        let items = [
            TMBarItem(title: "Posts"),
            TMBarItem(title: "Hashtags"),
            TMBarItem(title: "News"),
            TMBarItem(title: "For You"),
        ]
        return items
    }()
    
    var viewControllers: [ScrollViewContainer] {
        return [
            discoveryPostsViewController,
            discoveryHashtagsViewController,
            discoveryNewsViewController,
            discoveryForYouViewController,
        ]
    }
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        func setupDependency(_ needsDependency: NeedsDependency) {
            needsDependency.context = context
            needsDependency.coordinator = coordinator
        }
        
        self.context = context
        discoveryPostsViewController = {
            let viewController = DiscoveryPostsViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryPostsViewModel(context: context)
            return viewController
        }()
        discoveryHashtagsViewController = {
            let viewController = DiscoveryHashtagsViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryHashtagsViewModel(context: context)
            return viewController
        }()
        discoveryNewsViewController = {
            let viewController = DiscoveryNewsViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryNewsViewModel(context: context)
            return viewController
        }()
        discoveryForYouViewController = {
            let viewController = DiscoveryForYouViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryForYouViewModel(context: context)
            return viewController
        }()
        // end init
    }
    
}


// MARK: - PageboyViewControllerDataSource
extension DiscoveryViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }
    
}

// MARK: - TMBarDataSource
extension DiscoveryViewModel: TMBarDataSource {
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        return barItems[index]
    }
}
