//
//  UIViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import UIKit

extension UIViewController {
    
    /// Returns the top most view controller from given view controller's stack.
    var topMost: UIViewController? {
        // presented view controller
        if let presentedViewController = presentedViewController {
            return presentedViewController.topMost
        }
        
        // UITabBarController
        if let tabBarController = self as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topMost
        }
        
        // UINavigationController
        if let navigationController = self as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topMost
        }
        
        // UIPageController
        if let pageViewController = self as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return pageViewController.viewControllers?.first?.topMost ?? self
        }
        
        // child view controller
        for subview in self.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return childViewController.topMost
            }
        }
        
        return self
    }
    
}

extension UIViewController {

    func viewController<T: UIViewController>(of type: T.Type) -> T? {
        if let viewController = self as? T {
            return viewController
        }
        
        // UITabBarController
        if let tabBarController = self as? UITabBarController {
            for tab in tabBarController.viewControllers ?? [] {
                if let viewController = tab.viewController(of: type) {
                    return viewController
                }
            }
        }
        
        // UINavigationController
        if let navigationController = self as? UINavigationController {
            for page in navigationController.viewControllers {
                if let viewController = page.viewController(of: type) {
                    return viewController
                }
            }
        }
        
        // UIPageController
        if let pageViewController = self as? UIPageViewController {
            for page in pageViewController.viewControllers ?? [] {
                if let viewController = page.viewController(of: type) {
                    return viewController
                }
            }
        }
        
        // child view controller
        for subview in self.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController,
               let viewController = childViewController.viewController(of: type) {
                return viewController
            }
        }
        
        return nil
    }
    
}

extension UIViewController {
    
    /// https://bluelemonbits.com/2018/08/26/inserting-cells-at-the-top-of-a-uitableview-with-no-scrolling/
    static func topVisibleTableViewCellIndexPath(in tableView: UITableView, navigationBar: UINavigationBar) -> IndexPath? {
        let navigationBarRectInTableView = tableView.convert(navigationBar.bounds, from: navigationBar)
        let navigationBarMaxYPosition = CGPoint(x: 0, y: navigationBarRectInTableView.origin.y + navigationBarRectInTableView.size.height + 1)  // +1pt for UIKit cell locate
        let mostTopVisiableIndexPath = tableView.indexPathForRow(at: navigationBarMaxYPosition)
        return mostTopVisiableIndexPath
    }
    
    static func tableViewCellOriginOffsetToWindowTop(in tableView: UITableView, at indexPath: IndexPath, navigationBar: UINavigationBar) -> CGFloat {
        let rectForTopRow = tableView.rectForRow(at: indexPath)
        let navigationBarRectInTableView = tableView.convert(navigationBar.bounds, from: navigationBar)
        let navigationBarMaxYPosition = CGPoint(x: 0, y: navigationBarRectInTableView.origin.y + navigationBarRectInTableView.size.height)      // without +1pt
        let differenceBetweenTopRowAndNavigationBar = rectForTopRow.origin.y - navigationBarMaxYPosition.y
        return differenceBetweenTopRowAndNavigationBar
    }
    
}

extension UIViewController {
    
    /// https://stackoverflow.com/a/27301207/3797903
    var isModal: Bool {
        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController != nil && navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
    
}
