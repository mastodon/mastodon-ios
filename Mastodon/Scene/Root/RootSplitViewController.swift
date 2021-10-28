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
    
//    // .regular to .compact
//    // move navigation stack from .supplementary & .secondary to .compact
//    func splitViewController(
//        _ svc: UISplitViewController,
//        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
//    ) -> UISplitViewController.Column {
//        switch proposedTopColumn {
//        case .compact:
//            guard let index = MainTabBarController.Tab.allCases.firstIndex(of: currentSupplementaryTab) else {
//                assertionFailure()
//                break
//            }
//            mainTabBarController.selectedIndex = index
//            mainTabBarController.currentTab.value = currentSupplementaryTab
//
//            guard let navigationController = mainTabBarController.selectedViewController as? UINavigationController else { break }
//            navigationController.popToRootViewController(animated: false)
//            var viewControllers = navigationController.viewControllers      // init navigation stack with topMost
//
//            if let supplementaryNavigationController = viewController(for: .supplementary) as? UINavigationController {
//                // append supplementary
//                viewControllers.append(contentsOf: supplementaryNavigationController.popToRootViewController(animated: true) ?? [])
//            }
//            if let secondaryNavigationController = viewController(for: .secondary) as? UINavigationController {
//                // append secondary
//                viewControllers.append(contentsOf: secondaryNavigationController.popToRootViewController(animated: true) ?? [])
//            }
//            // set navigation stack
//            navigationController.setViewControllers(viewControllers, animated: false)
//
//        default:
//            assertionFailure()
//        }
//
//        return proposedTopColumn
//    }
//
//    // .compact to .regular
//    // restore navigation stack to .supplementary & .secondary
//    func splitViewController(
//        _ svc: UISplitViewController,
//        displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode
//    ) -> UISplitViewController.DisplayMode {
//        let compactNavigationController = mainTabBarController.selectedViewController as? UINavigationController
//
//        if let topMost = compactNavigationController?.topMost,
//           topMost is AccountListViewController {
//            topMost.dismiss(animated: false, completion: nil)
//        }
//
//        let viewControllers = compactNavigationController?.popToRootViewController(animated: true) ?? []
//
//        var supplementaryViewControllers: [UIViewController] = []
//        var secondaryViewControllers: [UIViewController] = []
//        for viewController in viewControllers {
//            if coordinator.secondaryStackHashValues.contains(viewController.hashValue) {
//                secondaryViewControllers.append(viewController)
//            } else {
//                supplementaryViewControllers.append(viewController)
//            }
//
//        }
//        if let supplementary = viewController(for: .supplementary) as? UINavigationController {
//            supplementary.setViewControllers(supplementary.viewControllers + supplementaryViewControllers, animated: false)
//        }
//        if let secondaryNavigationController = viewController(for: .secondary) as? UINavigationController {
//            secondaryNavigationController.setViewControllers(secondaryNavigationController.viewControllers + secondaryViewControllers, animated: false)
//        }
//
//        return proposedDisplayMode
//    }

}

//extension UIView {
//    func setNeedsLayoutForSubviews() {
//        self.subviews.forEach({
//            $0.setNeedsLayout()
//            $0.setNeedsLayoutForSubviews()
//        })
//    }
//}
