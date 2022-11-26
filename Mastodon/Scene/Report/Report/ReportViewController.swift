//
//  ReportViewController.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonAsset
import MastodonCore
import MastodonLocalization

class ReportViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    let logger = Logger(subsystem: "ReportViewController", category: "ViewController")

    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: ReportViewModel!
    
    lazy var cancelBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(ReportViewController.cancelBarButtonItemDidPressed(_:))
    )
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ReportViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem

        viewModel.reportReasonViewModel.delegate = self
        viewModel.reportServerRulesViewModel.delegate = self
        viewModel.reportStatusViewModel.delegate = self
        viewModel.reportSupplementaryViewModel.delegate = self
        
        let reportReasonViewController = ReportReasonViewController()
        reportReasonViewController.context = context
        reportReasonViewController.coordinator = coordinator
        reportReasonViewController.viewModel = viewModel.reportReasonViewModel
        
        addChild(reportReasonViewController)
        reportReasonViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reportReasonViewController.view)
        reportReasonViewController.didMove(toParent: self)
        reportReasonViewController.view.pinToParent()
    }
    
}

extension ReportViewController {
    
    @objc private func cancelBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ReportViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return viewModel.isReportSuccess
    }
}

// MARK: - ReportReasonViewControllerDelegate
extension ReportViewController: ReportReasonViewControllerDelegate {
    func reportReasonViewController(_ viewController: ReportReasonViewController, nextButtonPressed button: UIButton) {
        guard let reason = viewController.viewModel.selectReason else { return }
        switch reason {
        case .dislike:
            let reportResultViewModel = ReportResultViewModel(
                context: context,
                authContext: viewModel.authContext,
                user: viewModel.user,
                isReported: false
            )
            _ = coordinator.present(
                scene: .reportResult(viewModel: reportResultViewModel),
                from: self,
                transition: .show
            )
        case .violateRule:
            _ = coordinator.present(
                scene: .reportServerRules(viewModel: viewModel.reportServerRulesViewModel),
                from: self,
                transition: .show
            )
        case .spam, .other:
            _ = coordinator.present(
                scene: .reportStatus(viewModel: viewModel.reportStatusViewModel),
                from: self,
                transition: .show
            )
        }
    }
}

// MARK: - ReportServerRulesViewControllerDelegate
extension ReportViewController: ReportServerRulesViewControllerDelegate {
    func reportServerRulesViewController(_ viewController: ReportServerRulesViewController, nextButtonPressed button: UIButton) {
        guard !viewController.viewModel.selectRules.isEmpty else {
            return
        }
        
        _ = coordinator.present(
            scene: .reportStatus(viewModel: viewModel.reportStatusViewModel),
            from: self,
            transition: .show
        )
    }
}

// MARK: - ReportStatusViewControllerDelegate
extension ReportViewController: ReportStatusViewControllerDelegate {
    func reportStatusViewController(_ viewController: ReportStatusViewController, skipButtonDidPressed button: UIButton) {
        coordinateToReportSupplementary()
    }
    
    func reportStatusViewController(_ viewController: ReportStatusViewController, nextButtonDidPressed button: UIButton) {
        coordinateToReportSupplementary()
    }
    
    private func coordinateToReportSupplementary() {
        _ = coordinator.present(
            scene: .reportSupplementary(viewModel: viewModel.reportSupplementaryViewModel),
            from: self,
            transition: .show
        )
    }
}

// MARK: - ReportSupplementaryViewControllerDelegate
extension ReportViewController: ReportSupplementaryViewControllerDelegate {
    func reportSupplementaryViewController(_ viewController: ReportSupplementaryViewController, skipButtonDidPressed button: UIButton) {
        report()
    }
    
    func reportSupplementaryViewController(_ viewController: ReportSupplementaryViewController, nextButtonDidPressed button: UIButton) {
        report()
    }
    
    private func report() {
        Task { @MainActor in
            do {
                let _ = try await viewModel.report()
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): report success")
                
                let reportResultViewModel = ReportResultViewModel(
                    context: context,
                    authContext: viewModel.authContext,
                    user: viewModel.user,
                    isReported: true
                )
                
                _ = coordinator.present(
                    scene: .reportResult(viewModel: reportResultViewModel),
                    from: self,
                    transition: .show
                )
                
            } catch {
                let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                alertController.addAction(okAction)
                _ = self.coordinator.present(
                    scene: .alertController(alertController: alertController),
                    from: nil,
                    transition: .alertController(animated: true, completion: nil)
                )
            }
        }   // end Task
    }
    
}
