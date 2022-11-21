//
//  ReportStatusViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

protocol ReportStatusViewControllerDelegate: AnyObject {
    func reportStatusViewController(_ viewController: ReportStatusViewController, skipButtonDidPressed button: UIButton)
    func reportStatusViewController(_ viewController: ReportStatusViewController, nextButtonDidPressed button: UIButton)
}

class ReportStatusViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    let logger = Logger(subsystem: "ReportStatusViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
        
    var viewModel: ReportStatusViewModel!
    
    // MAKK: - UI
    
    lazy var cancelBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(ReportStatusViewController.cancelBarButtonItemDidPressed(_:))
    )
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.backgroundColor = Asset.Scene.Report.background.color
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.allowsMultipleSelection = true
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        } else {
            // Fallback on earlier versions
        }
        return tableView
    }()
    
    let navigationActionView: NavigationActionView = {
        let navigationActionView = NavigationActionView()
        navigationActionView.backgroundColor = Asset.Scene.Onboarding.background.color
        navigationActionView.backButton.setTitle(L10n.Common.Controls.Actions.skip, for: .normal)
        return navigationActionView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ReportStatusViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
                
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView
        )
        
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
                self.tableView.contentInset.bottom = inset
                self.tableView.verticalScrollIndicatorInsets.bottom = inset
            }
            .store(in: &observations)
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.view.window != nil else { return }
                self.viewModel.stateMachine.enter(ReportStatusViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        viewModel.$isNextButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: navigationActionView.nextButton)
            .store(in: &disposeBag)
        
        if !viewModel.selectStatuses.isEmpty {
            navigationActionView.hidesBackButton = true
        }
        
        navigationActionView.backButton.addTarget(self, action: #selector(ReportStatusViewController.skipButtonDidPressed(_:)), for: .touchUpInside)
        navigationActionView.nextButton.addTarget(self, action: #selector(ReportStatusViewController.nextButtonDidPressed(_:)), for: .touchUpInside)        
    }
    
}

extension ReportStatusViewController {
    
    @objc private func cancelBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func skipButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        assert(viewModel.delegate != nil)
        viewModel.isSkip = true
        viewModel.delegate?.reportStatusViewController(self, skipButtonDidPressed: sender)
    }

    @objc private func nextButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        assert(viewModel.delegate != nil)
        viewModel.isSkip = false
        viewModel.delegate?.reportStatusViewController(self, nextButtonDidPressed: sender)
    }

}

// MARK: - UITableViewDelegate
extension ReportStatusViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath),
              case .status = item
        else {
            return nil
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath),
              case let .status(record) = item
        else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        viewModel.selectStatuses.append(record)
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath),
              case let .status(record) = item
        else {
            return nil
        }
        
        // disallow deselect initial selection
        guard record != viewModel.status else { return nil }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath),
              case let .status(record) = item
        else {
            return
        }
                
        viewModel.selectStatuses.remove(record)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ReportStatusViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
