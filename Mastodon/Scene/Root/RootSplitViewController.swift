//
//  RootSplitViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import os.log
import UIKit
import Combine

final class RootSplitViewController: UISplitViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private(set) lazy var sidebarViewController: SidebarViewController = {
        let sidebarViewController = SidebarViewController()
        sidebarViewController.context = context
        sidebarViewController.coordinator = coordinator
        sidebarViewController.viewModel = SidebarViewModel(context: context)
        sidebarViewController.delegate = self
        return sidebarViewController
    }()
        
    var currentSupplementaryTab: MainTabBarController.Tab = .home
    private(set) lazy var supplementaryViewControllers: [UIViewController] = {
        let viewControllers = MainTabBarController.Tab.allCases.map { tab in
            tab.viewController(context: context, coordinator: coordinator)
        }
        for viewController in viewControllers {
            guard let navigationController = viewController as? UINavigationController else {
                assertionFailure()
                continue
            }
            if let homeViewController = navigationController.topViewController as? HomeTimelineViewController {
                homeViewController.viewModel.displaySettingBarButtonItem.value = false
            }
        }
        return viewControllers
    }()
    
    private(set) lazy var mainTabBarController = MainTabBarController(context: context, coordinator: coordinator)
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        super.init(style: .tripleColumn)
        
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        delegate = self
        
        if #available(iOS 14.5, *) {
            displayModeButtonVisibility = .always
        } else {
            // Fallback on earlier versions
        }
        
        setViewController(sidebarViewController, for: .primary)
        setViewController(supplementaryViewControllers[0], for: .supplementary)
        setViewController(UIViewController(), for: .secondary)
        setViewController(mainTabBarController, for: .compact)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension RootSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateBehavior(size: view.frame.size)
        
        mainTabBarController.currentTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tab in
                guard let self = self else { return }
                guard tab != self.currentSupplementaryTab else { return }
                guard let index = MainTabBarController.Tab.allCases.firstIndex(of: tab) else { return }
                self.currentSupplementaryTab = tab
                self.setViewController(self.supplementaryViewControllers[index], for: .supplementary)
                
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateBehavior(size: size)
    }
    
    private func updateBehavior(size: CGSize) {
        // fix secondary too small on iPad mini issue
        if size.width > 960 {
            preferredDisplayMode = .oneBesideSecondary
            preferredSplitBehavior = .tile
        } else {
            preferredDisplayMode = .oneBesideSecondary
            preferredSplitBehavior = .displace
        }
    }
    
}

// MARK: - SidebarViewControllerDelegate
extension RootSplitViewController: SidebarViewControllerDelegate {
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectTab tab: MainTabBarController.Tab) {
        
        guard let index = MainTabBarController.Tab.allCases.firstIndex(of: tab) else {
            assertionFailure()
            return
        }
        currentSupplementaryTab = tab
        setViewController(supplementaryViewControllers[index], for: .supplementary)
    }
}

// MARK: - UISplitViewControllerDelegate
extension RootSplitViewController: UISplitViewControllerDelegate {
    
    // .regular to .compact
    // move navigation stack from .supplementary & .secondary to .compact
    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        switch proposedTopColumn {
        case .compact:
            guard let index = MainTabBarController.Tab.allCases.firstIndex(of: currentSupplementaryTab) else {
                assertionFailure()
                break
            }
            mainTabBarController.selectedIndex = index
            mainTabBarController.currentTab.value = currentSupplementaryTab
            
            guard let navigationController = mainTabBarController.selectedViewController as? UINavigationController else { break }
            navigationController.popToRootViewController(animated: false)
            var viewControllers = navigationController.viewControllers      // init navigation stack with topMost

            if let supplementaryNavigationController = viewController(for: .supplementary) as? UINavigationController {
                // append supplementary
                viewControllers.append(contentsOf: supplementaryNavigationController.popToRootViewController(animated: true) ?? [])
            }
            if let secondaryNavigationController = viewController(for: .secondary) as? UINavigationController {
                // append secondary
                viewControllers.append(contentsOf: secondaryNavigationController.popToRootViewController(animated: true) ?? [])
            }
            // set navigation stack
            navigationController.setViewControllers(viewControllers, animated: false)
            
        default:
            assertionFailure()
        }

        return proposedTopColumn
    }
    
    // .compact to .regular
    // restore navigation stack to .supplementary & .secondary
    func splitViewController(
        _ svc: UISplitViewController,
        displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode
    ) -> UISplitViewController.DisplayMode {
        
        return proposedDisplayMode
    }
    
    func splitViewController(
        _ splitViewController: UISplitViewController,
        show vc: UIViewController,
        sender: Any?
    ) -> Bool {
        if !splitViewController.isCollapsed {
            // display in .secondary when expand
            splitViewController.showDetailViewController(vc, sender: sender)
            return true
        } else {
            return false
        }
    }
}
