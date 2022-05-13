//
//  ProfilePagingViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import XLPagerTabStrip
import TabBarPager

protocol ProfilePagingViewControllerDelegate: AnyObject {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController customScrollViewContainerController: ScrollViewContainer, atIndex index: Int)
}

final class ProfilePagingViewController: ButtonBarPagerTabStripViewController, TabBarPageViewController {
    
    weak var tabBarPageViewDelegate: TabBarPageViewDelegate?
    weak var pagingDelegate: ProfilePagingViewControllerDelegate?
    
    var viewModel: ProfilePagingViewModel!
    
    // MARK: - TabBarPageViewController
    
    var currentPage: TabBarPage? {
        return viewModel.viewControllers[currentIndex]
    }
    
    var currentPageIndex: Int? {
        currentIndex
    }
    
    // MARK: - ButtonBarPagerTabStripViewController
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return viewModel.viewControllers
    }
    
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        
        guard indexWasChanged else { return }
        let page = viewModel.viewControllers[toIndex]
        tabBarPageViewDelegate?.pageViewController(self, didPresentingTabBarPage: page, at: toIndex)
    }
    
    // make key commands works
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = .clear
//        dataSource = viewModel
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        becomeFirstResponder()
    }

}

// workaround to fix tab man responder chain issue
extension ProfilePagingViewController {

//    override var keyCommands: [UIKeyCommand]? {
//        return currentPage?.keyCommands
//    }
//
//    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        (currentViewController as? StatusTableViewControllerNavigateable)?.navigateKeyCommandHandlerRelay(sender)
//
//    }
//
//    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        (currentViewController as? StatusTableViewControllerNavigateable)?.statusKeyCommandHandlerRelay(sender)
//    }
        
}
