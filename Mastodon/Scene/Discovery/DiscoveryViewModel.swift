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
    let discoveryPostsViewController: DiscoveryPostsViewController
    let newDiscoveryPostsViewController: HomeTimelineListViewController
    let discoveryHashtagsViewController: DiscoveryHashtagsViewController
    let discoveryNewsViewController: DiscoveryNewsViewController
    let discoveryForYouViewController: DiscoveryForYouViewController
    
    @Published var viewControllers: [UIViewController]
    
    @MainActor
    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
        
        discoveryPostsViewController = {
            let viewController = DiscoveryPostsViewController()
            viewController.viewModel = DiscoveryPostsViewModel(authenticationBox: authenticationBox)
            return viewController
        }()
        newDiscoveryPostsViewController = {
            HomeTimelineListViewController(.trendingPosts)
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
            (UserDefaults.standard.testNewHomeTimeline ? newDiscoveryPostsViewController : discoveryPostsViewController),
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
