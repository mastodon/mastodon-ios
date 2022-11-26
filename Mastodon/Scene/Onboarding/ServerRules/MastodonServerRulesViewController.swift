//
//  MastodonServerRulesViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-22.
//

import os.log
import UIKit
import Combine
import MastodonSDK
import SafariServices
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class MastodonServerRulesViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "MastodonServerRulesViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonServerRulesViewModel!
    
    let stackView = UIStackView()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(OnboardingHeadlineTableViewCell.self, forCellReuseIdentifier: String(describing: OnboardingHeadlineTableViewCell.self))
        tableView.register(ServerRulesTableViewCell.self, forCellReuseIdentifier: String(describing: ServerRulesTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }
        return tableView
    }()

    let navigationActionView: NavigationActionView = {
        let navigationActionView = NavigationActionView()
        navigationActionView.backgroundColor = Asset.Scene.Onboarding.background.color
        return navigationActionView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
     
}

extension MastodonServerRulesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem()

        setupOnboardingAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
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
            }
            .store(in: &observations)
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(tableView: tableView)

        navigationActionView.backButton.addTarget(self, action: #selector(MastodonServerRulesViewController.backButtonPressed(_:)), for: .touchUpInside)
        navigationActionView.nextButton.addTarget(self, action: #selector(MastodonServerRulesViewController.nextButtonPressed(_:)), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
}

extension MastodonServerRulesViewController {
    
    @objc private func backButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func nextButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        let viewModel = MastodonRegisterViewModel(
            context: context,
            domain: viewModel.domain,
            authenticateInfo: viewModel.authenticateInfo,
            instance: viewModel.instance,
            applicationToken: viewModel.applicationToken
        )
        _ = coordinator.present(scene: .mastodonRegister(viewModel: viewModel), from: self, transition: .show)
    }
    
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonServerRulesViewController: OnboardingViewControllerAppearance { }

// MARK: - UITableViewDelegate
extension MastodonServerRulesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource,
              section < diffableDataSource.snapshot().numberOfSections
        else { return .leastNonzeroMagnitude }
        
        let sectionItem = diffableDataSource.snapshot().sectionIdentifiers[section]
        switch sectionItem {
        case .header:
            return .leastNonzeroMagnitude
        case .rules:
            return 16
        }
    }
}
