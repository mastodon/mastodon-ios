//
//  RootSplitViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import os.log
import UIKit

final class RootSplitViewController: UISplitViewController, NeedsDependency {
    
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
    
    private(set) lazy var mainTabBarController = MainTabBarController(context: context, coordinator: coordinator)
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        super.init(style: .tripleColumn)
        
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        
        if #available(iOS 14.5, *) {
            displayModeButtonVisibility = .always
        } else {
            // Fallback on earlier versions
        }
        
        setViewController(sidebarViewController, for: .primary)
        setViewController(mainTabBarController.viewControllers!.first, for: .supplementary)
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
        
        // FIXME: remove hard code
        switch tab {
        case .home:
            setViewController(mainTabBarController._viewControllers[0], for: .supplementary)
        case .search:
            setViewController(mainTabBarController._viewControllers[1], for: .supplementary)
        case .notification:
            setViewController(mainTabBarController._viewControllers[2], for: .supplementary)
        case .me:
            setViewController(mainTabBarController._viewControllers[3], for: .supplementary)
        }
    }
}
