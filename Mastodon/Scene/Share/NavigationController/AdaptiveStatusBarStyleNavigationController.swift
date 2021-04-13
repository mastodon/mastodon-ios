//
//  AdaptiveStatusBarStyleNavigationController.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-26.
//

import UIKit

// Make status bar style adptive for child view controller
// SeeAlso: `modalPresentationCapturesStatusBarAppearance`
final class AdaptiveStatusBarStyleNavigationController: UINavigationController {
    var viewControllersHiddenNavigationBar: [UIViewController.Type]

    override var childForStatusBarStyle: UIViewController? {
        visibleViewController
    }

    override init(rootViewController: UIViewController) {
        self.viewControllersHiddenNavigationBar = [SearchViewController.self]
        super.init(rootViewController: rootViewController)
        self.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AdaptiveStatusBarStyleNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isContain = self.viewControllersHiddenNavigationBar.contains { type(of: viewController) == $0 }
        if isContain {
            self.setNavigationBarHidden(true, animated: animated)
        } else {
            self.setNavigationBarHidden(false, animated: animated)
        }
    }
}
