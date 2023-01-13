//
//  ReportSupplementaryViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

protocol ReportSupplementaryViewControllerDelegate: AnyObject {
    func reportSupplementaryViewController(_ viewController: ReportSupplementaryViewController, submitButtonDidPressed button: UIButton)
}

final class ReportSupplementaryViewController: UIViewController, NeedsDependency, ReportViewControllerAppearance {
    
    let logger = Logger(subsystem: "ReportSupplementaryViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: ReportSupplementaryViewModel! { willSet { precondition(!isViewLoaded) } }

    // MAKK: - UI
    
    lazy var cancelBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(ReportSupplementaryViewController.cancelBarButtonItemDidPressed(_:))
    )
    
    let activityIndicatorBarButtonItem: UIBarButtonItem = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.startAnimating()
        let barButtonItem = UIBarButtonItem(customView: activityIndicatorView)
        return barButtonItem
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.backgroundColor = Asset.Scene.Report.background.color
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        return tableView
    }()
    
    let navigationActionView: NavigationActionView = {
        let navigationActionView = NavigationActionView()
        navigationActionView.backgroundColor = Asset.Scene.Onboarding.background.color
        navigationActionView.nextButton.setTitle(L10n.Common.Controls.Actions.submit, for: .normal)
        navigationActionView.hidesBackButton = true
        return navigationActionView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ReportSupplementaryViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        viewModel.$isBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBusy in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem = isBusy ? self.activityIndicatorBarButtonItem : self.cancelBarButtonItem
                self.navigationItem.hidesBackButton = isBusy
                self.navigationActionView.nextButton.isUserInteractionEnabled = !isBusy
            }
            .store(in: &disposeBag)

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
        
        navigationActionView.nextButton.addTarget(self, action: #selector(ReportSupplementaryViewController.submitButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension ReportSupplementaryViewController {
    
    @objc private func cancelBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc func submitButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        assert(viewModel.delegate != nil)
        viewModel.delegate?.reportSupplementaryViewController(self, submitButtonDidPressed: sender)
    }
}

// MARK: - UITableViewDelegate
extension ReportSupplementaryViewController: UITableViewDelegate { }
