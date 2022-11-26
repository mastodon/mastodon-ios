//
//  ReportResultViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-8.
//

import os.log
import UIKit
import SwiftUI
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class ReportResultViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: ReportResultViewModel!
    private(set) lazy var reportResultView = ReportResultView(viewModel: viewModel)

    lazy var doneBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(ReportResultViewController.doneBarButtonItemDidPressed(_:))
    )
    
    let navigationActionView: NavigationActionView = {
        let navigationActionView = NavigationActionView()
        navigationActionView.backgroundColor = Asset.Scene.Onboarding.background.color
        navigationActionView.hidesBackButton = true
        navigationActionView.nextButton.setTitle(L10n.Common.Controls.Actions.done, for: .normal)
        return navigationActionView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ReportResultViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = doneBarButtonItem
        
        let hostingViewController = UIHostingController(rootView: reportResultView)
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
        
        
        navigationActionView.nextButton.addTarget(self, action: #selector(ReportSupplementaryViewController.nextButtonDidPressed(_:)), for: .touchUpInside)
        
        viewModel.followActionPublisher
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    guard !self.viewModel.isRequestFollow else { return }
                    self.viewModel.isRequestFollow = true
                    do {
                        try await DataSourceFacade.responseToUserFollowAction(
                            dependency: self,
                            user: self.viewModel.user
                        )
                    } catch {
                        // handle error
                    }
                    self.viewModel.isRequestFollow = false
                }   // end Task
            }
            .store(in: &disposeBag)
        
        viewModel.muteActionPublisher
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    guard !self.viewModel.isRequestMute else { return }
                    self.viewModel.isRequestMute = true
                    do {
                        try await DataSourceFacade.responseToUserMuteAction(
                            dependency: self,
                            user: self.viewModel.user
                        )
                    } catch {
                        // handle error
                    }
                    self.viewModel.isRequestMute = false
                }   // end Task
            }
            .store(in: &disposeBag)
        
        viewModel.blockActionPublisher
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    guard !self.viewModel.isRequestBlock else { return }
                    self.viewModel.isRequestBlock = true
                    do {
                        try await DataSourceFacade.responseToUserBlockAction(
                            dependency: self,
                            user: self.viewModel.user
                        )
                    } catch {
                        // handle error
                    }
                    self.viewModel.isRequestBlock = false
                }   // end Task
            }
            .store(in: &disposeBag)
    }
    
}

extension ReportResultViewController {
    
    @objc func doneBarButtonItemDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @objc func nextButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - AuthContextProvider
extension ReportResultViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - PanPopableViewController
extension ReportResultViewController: PanPopableViewController {
    var isPanPopable: Bool { false }
}
