//
//  ReportServerRulesViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import os.log
import UIKit
import SwiftUI
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

protocol ReportServerRulesViewControllerDelegate: AnyObject {
    func reportServerRulesViewController(_ viewController: ReportServerRulesViewController, nextButtonPressed button: UIButton)
}

final class ReportServerRulesViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    let logger = Logger(subsystem: "ReportReasonViewController", category: "ViewController")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()
        
    var viewModel: ReportServerRulesViewModel!
    private(set) lazy var reportServerRulesView = ReportServerRulesView(viewModel: viewModel)
    
    lazy var cancelBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(ReportServerRulesViewController.cancelBarButtonItemDidPressed(_:))
    )
    
    let navigationActionView: NavigationActionView = {
        let navigationActionView = NavigationActionView()
        navigationActionView.backgroundColor = Asset.Scene.Onboarding.background.color
        navigationActionView.hidesBackButton = true
        return navigationActionView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ReportServerRulesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        let hostingViewController = UIHostingController(rootView: reportServerRulesView)
        hostingViewController.view.preservesSuperviewLayoutMargins = true
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        hostingViewController.view.pinToParent()
        
        navigationActionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationActionView)
        defer {
            view.bringSubviewToFront(navigationActionView)
        }
        NSLayoutConstraint.activate([
            navigationActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: navigationActionView.bottomAnchor),
        ])
        
        navigationActionView
            .observe(\.bounds, options: [.initial, .new]) { [weak self] navigationActionView, _ in
                guard let self = self else { return }
                let inset = navigationActionView.frame.height
                self.viewModel.bottomPaddingHeight = inset
            }
            .store(in: &observations)
        
        viewModel.$selectRules
            .map { !$0.isEmpty }
            .assign(to: \.isEnabled, on: navigationActionView.nextButton)
            .store(in: &disposeBag)
        
        navigationActionView.nextButton.addTarget(self, action: #selector(ReportServerRulesViewController.nextButtonPressed(_:)), for: .touchUpInside)        
    }
    
}

extension ReportServerRulesViewController {
    
    @objc private func cancelBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func nextButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        assert(viewModel.delegate != nil)
        viewModel.delegate?.reportServerRulesViewController(self, nextButtonPressed: sender)
    }
    
}
