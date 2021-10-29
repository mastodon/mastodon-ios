//
//  RootSplitViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import os.log
import UIKit
import Combine
import CoreDataStack

final class RootSplitViewController: UISplitViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    static let sidebarWidth: CGFloat = 89
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private(set) lazy var contentSplitViewController: ContentSplitViewController = {
        let contentSplitViewController = ContentSplitViewController()
        contentSplitViewController.context = context
        contentSplitViewController.coordinator = coordinator
        return contentSplitViewController
    }()
    
    lazy var compactMainTabBarViewController = MainTabBarController(context: context, coordinator: coordinator)
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        super.init(style: .doubleColumn)
        
        primaryEdge = .trailing
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .twoBesideSecondary
        preferredSplitBehavior = .tile
        delegate = self
        
        // disable edge swipe gesture
        presentsWithGesture = false
        
        if #available(iOS 14.5, *) {
            displayModeButtonVisibility = .never
        } else {
            // Fallback on earlier versions
        }
        
        setViewController(UIViewController(), for: .primary)
        setViewController(contentSplitViewController, for: .secondary)
        setViewController(compactMainTabBarViewController, for: .compact)
        
        contentSplitViewController.sidebarViewController.view.layer.zPosition = 100
        contentSplitViewController.mainTabBarController.view.layer.zPosition = 90
        view.layer.zPosition = 80
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
        contentSplitViewController.$currentSupplementaryTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateBehavior(size: self.view.frame.size)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [weak self] context in
            guard let self = self else { return }
            self.updateBehavior(size: size)
        } completion: { context in
            // do nothing
        }
    }
    
    private func updateBehavior(size: CGSize) {
        switch contentSplitViewController.currentSupplementaryTab {
        case .search:
            hide(.primary)
        default:
            if size.width > 960 {
                show(.primary)
            } else {
                hide(.primary)
            }
        }
    }

}

// MARK: - UISplitViewControllerDelegate
extension RootSplitViewController: UISplitViewControllerDelegate {
    
    private static  func transform(from: UITabBarController, to: UITabBarController) {
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
    
    // .regular to .compact
    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        switch proposedTopColumn {
        case .compact:
            RootSplitViewController.transform(from: contentSplitViewController.mainTabBarController, to: compactMainTabBarViewController)
            compactMainTabBarViewController.currentTab.value = contentSplitViewController.currentSupplementaryTab

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
        contentSplitViewController.currentSupplementaryTab = compactMainTabBarViewController.currentTab.value

        return proposedDisplayMode
    }

}
