//
//  RootSplitViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import UIKit
import CoreDataStack
import MastodonCore

final class RootSplitViewController: UISplitViewController {
    static let sidebarWidth: CGFloat = 89
    
    var authenticationBox: MastodonAuthenticationBox?
    
    private var isPrimaryDisplay = false
    
    private(set) lazy var contentSplitViewController: ContentSplitViewController = {
        let contentSplitViewController = ContentSplitViewController()
        contentSplitViewController.authenticationBox = authenticationBox
        contentSplitViewController.delegate = self
        return contentSplitViewController
    }()
    
    
    lazy var compactMainTabBarViewController = MainTabBarController(authenticationBox: authenticationBox)
    
    let separatorLine = UIView.separatorLine
    
    init(authenticationBox: MastodonAuthenticationBox?) {
        self.authenticationBox = authenticationBox
        super.init(style: .doubleColumn)
        
        primaryEdge = .trailing
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .twoBesideSecondary
        preferredSplitBehavior = .tile
        delegate = self
        
        // disable edge swipe gesture
        presentsWithGesture = false
        
        displayModeButtonVisibility = .never
        
        setViewController(contentSplitViewController, for: .secondary)
        setViewController(compactMainTabBarViewController, for: .compact)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension RootSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateBehavior(size: view.frame.size)
        
        view.backgroundColor = .separator
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateBehavior(size: view.frame.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.updateBehavior(size: size)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portraitOnPhone
    }

    private func updateBehavior(size: CGSize) {
        if size.width > 960 {
            show(.primary)
            isPrimaryDisplay = true
            
        } else {
            hide(.primary)
            isPrimaryDisplay = false
        }
        
        switch (contentSplitViewController.currentSupplementaryTab, isPrimaryDisplay) {
        case (.search, true):
            // needs switch to other tab when primary display
            // use FIFO queue save tab history
            contentSplitViewController.currentSupplementaryTab = .home
        default:
            // do nothing
            break
        }
    }

}

// MARK: - ContentSplitViewControllerDelegate
extension RootSplitViewController: ContentSplitViewControllerDelegate {
    func contentSplitViewController(_ contentSplitViewController: ContentSplitViewController, sidebarViewController: SidebarViewController, didSelectTab tab: Tab) {
        guard let _ = Tab.allCases.firstIndex(of: tab) else {
            assertionFailure()
            return
        }
        switch tab {
        case .search:
            fallthrough
        
        default:
            let previousTab = contentSplitViewController.currentSupplementaryTab
            contentSplitViewController.currentSupplementaryTab = tab
            
            if previousTab == tab,
               let navigationController = contentSplitViewController.mainTabBarController.selectedViewController as? UINavigationController
            {
                navigationController.popToRootViewController(animated: true)
            }
            
        }
    }
    
    func contentSplitViewController(_ contentSplitViewController: ContentSplitViewController, sidebarViewController: SidebarViewController, didDoubleTapTab tab: Tab) {
        guard let _ = Tab.allCases.firstIndex(of: tab) else {
            assertionFailure()
            return
        }
        
        switch tab {
        case .search:
            // allow double tap to focus search bar only when is not primary display (iPad potrait)
            guard !isPrimaryDisplay else {
                return
            }
            contentSplitViewController.mainTabBarController.searchViewController.searchBar.becomeFirstResponder()
        default:
            break
        }
    }
}

// MARK: - UISplitViewControllerDelegate
extension RootSplitViewController: UISplitViewControllerDelegate {
    
    private static func transform(from: UITabBarController, to: UITabBarController) {
        let sourceNavigationControllers = from.viewControllers ?? []
        let targetNavigationControllers = to.viewControllers ?? []
        
        for (source, target) in zip(sourceNavigationControllers, targetNavigationControllers) {
            guard let source = source as? UINavigationController,
                  let target = target as? UINavigationController
            else { continue }
            let viewControllers = source.popToRootViewController(animated: false) ?? []
            _ = target.popToRootViewController(animated: false)
            target.viewControllers.append(contentsOf: viewControllers)
        }
        
        to.selectedIndex = from.selectedIndex
    }
    
    private static func transform(from: UINavigationController, to: UINavigationController) {
        let viewControllers = from.popToRootViewController(animated: false) ?? []
        to.viewControllers.append(contentsOf: viewControllers)
    }
    
    // .regular to .compact
    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        switch proposedTopColumn {
        case .compact:
            RootSplitViewController.transform(from: contentSplitViewController.mainTabBarController, to: compactMainTabBarViewController)
            compactMainTabBarViewController.currentTab = contentSplitViewController.currentSupplementaryTab

        default:
            assertionFailure()
        }

        return proposedTopColumn
    }
    
    // .compact to .regular
    func splitViewController(
        _ svc: UISplitViewController,
        displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode
    ) -> UISplitViewController.DisplayMode {
        let compactNavigationController = compactMainTabBarViewController.selectedViewController as? UINavigationController

        if let topMost = compactNavigationController?.topMost,
           topMost is AccountListViewController {
            topMost.dismiss(animated: false, completion: nil)
        }

        RootSplitViewController.transform(from: compactMainTabBarViewController, to: contentSplitViewController.mainTabBarController)
        
        let tab = compactMainTabBarViewController.currentTab
        if tab == .search {
            contentSplitViewController.currentSupplementaryTab = .home
        } else {
            contentSplitViewController.currentSupplementaryTab = compactMainTabBarViewController.currentTab
        }

        return proposedDisplayMode
    }

}
