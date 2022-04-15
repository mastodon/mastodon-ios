//
//  DiscoveryViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import UIKit
import Combine
import Tabman
import Pageboy

final class DiscoveryViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let discoveryPostsViewController: DiscoveryPostsViewController
    let discoveryHashtagsViewController: DiscoveryHashtagsViewController
    let discoveryNewsViewController: DiscoveryNewsViewController
    let discoveryForYouViewController: DiscoveryForYouViewController
    
    @Published var viewControllers: [ScrollViewContainer & PageViewController]
    
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
        self.viewControllers = [
            discoveryPostsViewController,
            discoveryHashtagsViewController,
            discoveryNewsViewController,
            discoveryForYouViewController,
        ]
        // end init
        
        discoveryPostsViewController.viewModel.$isServerSupportEndpoint
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isServerSupportEndpoint in
                guard let self = self else { return }
                if !isServerSupportEndpoint {
                    self.viewControllers.removeAll(where: {
                        $0 === self.discoveryPostsViewController || $0 === self.discoveryPostsViewController
                    })
                }
            }
            .store(in: &disposeBag)
        
        discoveryNewsViewController.viewModel.$isServerSupportEndpoint
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isServerSupportEndpoint in
                guard let self = self else { return }
                if !isServerSupportEndpoint {
                    self.viewControllers.removeAll(where: { $0 === self.discoveryNewsViewController })
                }
            }
            .store(in: &disposeBag)
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
        guard !viewControllers.isEmpty, index < viewControllers.count else {
            assertionFailure()
            return TMBarItem(title: "")
        }
        return viewControllers[index].tabItem
    }
}

protocol PageViewController: UIViewController {
    var tabItemTitle: String { get }
    var tabItem: TMBarItemable { get }
}

// MARK: - PageViewController
extension DiscoveryPostsViewController: PageViewController {
    var tabItemTitle: String { "Posts" }
    var tabItem: TMBarItemable {
        return TMBarItem(title: tabItemTitle)
    }
}


// MARK: - PageViewController
extension DiscoveryHashtagsViewController: PageViewController {
    var tabItemTitle: String { "Hashtags" }
    var tabItem: TMBarItemable {

        return TMBarItem(title: tabItemTitle)
    }
}

// MARK: - PageViewController
extension DiscoveryNewsViewController: PageViewController {
    var tabItemTitle: String { "News" }
    var tabItem: TMBarItemable {
        return TMBarItem(title: tabItemTitle)
    }
}

// MARK: - PageViewController
extension DiscoveryForYouViewController: PageViewController {
    var tabItemTitle: String { "For You" }
    var tabItem: TMBarItemable {
        return TMBarItem(title: tabItemTitle)
    }
}
