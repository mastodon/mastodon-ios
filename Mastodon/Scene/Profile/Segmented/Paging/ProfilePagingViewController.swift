//
//  ProfilePagingViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import Pageboy
import Tabman

protocol ProfilePagingViewControllerDelegate: AnyObject {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController customScrollViewContainerController: ScrollViewContainer, atIndex index: Int)
}

final class ProfilePagingViewController: TabmanViewController {
    
    weak var pagingDelegate: ProfilePagingViewControllerDelegate?
    var viewModel: ProfilePagingViewModel!
    
    
    // MARK: - PageboyViewControllerDelegate
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
        
        let viewController = viewModel.viewControllers[index]
        pagingDelegate?.profilePagingViewController(self, didScrollToPostCustomScrollViewContainerController: viewController, atIndex: index)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        dataSource = viewModel
    }

}
