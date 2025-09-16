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
    let authenticationBox: MastodonAuthenticationBox
    let newDiscoveryPostsViewController: TimelineListViewController
    let discoveryHashtagsViewController: DiscoveryHashtagsViewController
    let discoveryNewsViewController: DiscoveryNewsViewController
    let discoveryForYouViewController: DiscoveryForYouViewController
    
    @Published var viewControllers: [UIViewController]
    
    @MainActor
    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
        
        newDiscoveryPostsViewController = {
            TimelineListViewController(.trendingPosts)
        }()
        discoveryHashtagsViewController = {
            let viewController = DiscoveryHashtagsViewController()
            viewController.viewModel = DiscoveryHashtagsViewModel(authenticationBox: authenticationBox)
            return viewController
        }()
        discoveryNewsViewController = {
            let viewController = DiscoveryNewsViewController()
            viewController.viewModel = DiscoveryNewsViewModel(authenticationBox: authenticationBox)
            return viewController
        }()
        discoveryForYouViewController = {
            let viewController = DiscoveryForYouViewController()
            viewController.viewModel = DiscoveryForYouViewModel(authenticationBox: authenticationBox)
            return viewController
        }()
        self.viewControllers = [
            newDiscoveryPostsViewController,
            discoveryHashtagsViewController,
            discoveryNewsViewController,
            discoveryForYouViewController,
        ]
        // end init
        
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
