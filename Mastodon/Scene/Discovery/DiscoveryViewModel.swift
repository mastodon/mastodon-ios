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
    let discoveryViewController: DiscoveryPostsViewController
    
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
            discoveryViewController,
        ]
    }
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        discoveryViewController = {
            let viewController = DiscoveryPostsViewController()
            viewController.context = context
            viewController.coordinator = coordinator
            viewController.viewModel = DiscoveryPostsViewModel(context: context)
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
