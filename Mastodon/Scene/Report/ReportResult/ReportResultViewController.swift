//
//  ReportResultViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-8.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization

final class ReportResultViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: ReportResultViewModel!
    
    lazy var doneBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(ReportResultViewController.doneBarButtonItemDidPressed(_:))
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
        
        
        navigationActionView.nextButton.addTarget(self, action: #selector(ReportSupplementaryViewController.nextButtonDidPressed(_:)), for: .touchUpInside)
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

// MARK: - UITableViewDelegate
extension ReportResultViewController: UITableViewDelegate { }

// MARK: - PanPopableViewController
extension ReportResultViewController: PanPopableViewController {
    var isPanPopable: Bool { false }
}
