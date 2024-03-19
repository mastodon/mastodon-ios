//
//  DiscoveryViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import UIKit
import Combine
import Pageboy
import MastodonCore
import MastodonLocalization

final class DiscoveryViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let discoveryPostsViewController: DiscoveryPostsViewController
    let discoveryHashtagsViewController: DiscoveryHashtagsViewController
    let discoveryNewsViewController: DiscoveryNewsViewController
    let discoveryForYouViewController: DiscoveryForYouViewController
    
    @Published var viewControllers: [ScrollViewContainer]
    
    @MainActor
    init(context: AppContext, coordinator: SceneCoordinator, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        
        func setupDependency(_ needsDependency: NeedsDependency) {
            needsDependency.context = context
            needsDependency.coordinator = coordinator
        }
        
        discoveryPostsViewController = {
            let viewController = DiscoveryPostsViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryPostsViewModel(context: context, authContext: authContext)
            return viewController
        }()
        discoveryHashtagsViewController = {
            let viewController = DiscoveryHashtagsViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryHashtagsViewModel(context: context, authContext: authContext)
            return viewController
        }()
        discoveryNewsViewController = {
            let viewController = DiscoveryNewsViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryNewsViewModel(context: context, authContext: authContext)
            return viewController
        }()
        discoveryForYouViewController = {
            let viewController = DiscoveryForYouViewController()
            setupDependency(viewController)
            viewController.viewModel = DiscoveryForYouViewModel(context: context, authContext: authContext)
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
