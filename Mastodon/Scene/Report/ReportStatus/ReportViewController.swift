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
import MastodonLocalization

class ReportViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: ReportViewModel!
    
    // MAKK: - UI
    lazy var cancelBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(ReportViewController.cancelBarButtonItemDidPressed(_:))
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

extension ReportViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
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
                self.viewModel.stateMachine.enter(ReportViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        viewModel.$isNextButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: navigationActionView.nextButton)
            .store(in: &disposeBag)
        
        navigationActionView.backButton.addTarget(self, action: #selector(ReportViewController.skipButtonDidPressed(_:)), for: .touchUpInside)
        navigationActionView.nextButton.addTarget(self, action: #selector(ReportViewController.nextButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension ReportViewController {

    @objc private func cancelBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc func skipButtonDidPressed(_ sender: UIButton) {
        var selectStatuses: [ManagedObjectRecord<Status>] = []
        if let selectStatus = viewModel.status {
            selectStatuses.append(selectStatus)
        }
        
        let reportSupplementaryViewModel = ReportSupplementaryViewModel(
            context: context,
            user: viewModel.user,
            selectStatuses: selectStatuses
        )
        coordinator.present(
            scene: .reportSupplementary(viewModel: reportSupplementaryViewModel),
            from: self,
            transition: .show
        )
    }

    @objc func nextButtonDidPressed(_ sender: UIButton) {
        let selectStatuses = Array(viewModel.selectStatuses)
        guard !selectStatuses.isEmpty else { return }
        
        let reportSupplementaryViewModel = ReportSupplementaryViewModel(
            context: context,
            user: viewModel.user,
            selectStatuses: selectStatuses
        )
        coordinator.present(
            scene: .reportSupplementary(viewModel: reportSupplementaryViewModel),
            from: self,
            transition: .show
        )
    }

}

// MARK: - UITableViewDelegate
extension ReportViewController: UITableViewDelegate {
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
extension ReportViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
