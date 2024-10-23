// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit

protocol NavigationFlowPresenter {
    var currentlyDisplayedViewController: UIViewController? { get }
    func show(
        _ viewController: UIViewController,
        preferredDetents: [UISheetPresentationController.Detent])
    func dismissFlow(initialViewController: UIViewController?)
    func showAlert(_ alert: UIAlertController)
}

@MainActor
class NavigationFlow {
    let flowPresenter: NavigationFlowPresenter
    let initialViewController: UIViewController?
    private var completionHandler: (() -> Void)?

    init(flowPresenter: NavigationFlowPresenter) {
        self.flowPresenter = flowPresenter
        initialViewController = flowPresenter.currentlyDisplayedViewController
    }

    final func presentFlow(completionHandler: @escaping (() -> Void)) {
        self.completionHandler = completionHandler
        startFlow()
    }

    func startFlow() {
        fatalError("subclasses must implement")
    }

    final func dismissFlow() {
        flowPresenter.dismissFlow(initialViewController: initialViewController)
        completionHandler?()
    }
}

extension UIViewController: NavigationFlowPresenter {
    var currentlyDisplayedViewController: UIViewController? {
        if let nav = self as? UINavigationController {
            return nav.topViewController
        } else {
            return self.presentedViewController
        }
    }

    func show(
        _ viewController: UIViewController,
        preferredDetents: [UISheetPresentationController.Detent]
    ) {
        if let nav = self as? UINavigationController {
            nav.pushViewController(viewController, animated: true)
        } else {
            if presentedViewController != nil {
                dismiss(animated: true)
            }
            viewController.modalPresentationStyle = .pageSheet
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = preferredDetents
            }
            present(viewController, animated: true, completion: nil)
        }
    }

    func dismissFlow(initialViewController: UIViewController?) {
        if let nav = self as? UINavigationController {
            if let initialViewController = initialViewController {
                nav.popToViewController(initialViewController, animated: true)
            } else {
                nav.popToRootViewController(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }

    func showAlert(_ alert: UIAlertController) {
        if let nav = self as? UINavigationController {
            nav.topViewController?.present(alert, animated: true)
        } else {
            dismiss(animated: true)
            present(alert, animated: true)
        }
    }
}
