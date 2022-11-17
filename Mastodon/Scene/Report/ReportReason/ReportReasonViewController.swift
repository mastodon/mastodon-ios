//
//  ReportReasonViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import os.log
import UIKit
import SwiftUI
import Combine
import MastodonUI
import MastodonAsset
import MastodonCore
import MastodonLocalization

protocol ReportReasonViewControllerDelegate: AnyObject {
    func reportReasonViewController(_ viewController: ReportReasonViewController, nextButtonPressed button: UIButton)
}

final class ReportReasonViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    let logger = Logger(subsystem: "ReportReasonViewController", category: "ViewController")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
        
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()
    
    var viewModel: ReportReasonViewModel!
    private(set) lazy var reportReasonView = ReportReasonView(viewModel: viewModel)
    
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

extension ReportReasonViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        let hostingViewController = UIHostingController(rootView: reportReasonView)
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
        
        viewModel.$selectReason
            .map { $0 != nil }
            .assign(to: \.isEnabled, on: navigationActionView.nextButton)
            .store(in: &disposeBag)
        
        navigationActionView.nextButton.addTarget(self, action: #selector(ReportReasonViewController.nextButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension ReportReasonViewController {
    
    @objc private func nextButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        assert(viewModel.delegate != nil)
        viewModel.delegate?.reportReasonViewController(self, nextButtonPressed: sender)
    }
    
}
