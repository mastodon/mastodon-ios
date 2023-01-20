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

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(ServerRulesTableViewCell.self, forCellReuseIdentifier: String(describing: ServerRulesTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionHeaderTopPadding = 0
        return tableView
    }()
}

extension MastodonServerRulesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
        viewModel.setupDiffableDataSource(tableView: tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.Scene.ServerRules.Button.confirm, style: .done, target: self, action: #selector(MastodonServerRulesViewController.nextButtonPressed(_:)))
        title = L10n.Scene.ServerRules.title
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
}

extension MastodonServerRulesViewController {
    @objc private func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @objc private func nextButtonPressed(_ sender: UIButton) {
        let domain = viewModel.domain
        let viewModel = PrivacyViewModel(domain: domain, authenticateInfo: viewModel.authenticateInfo, rows: [.iOSApp, .server(domain: domain)], instance: viewModel.instance, applicationToken: viewModel.applicationToken)

        _ = coordinator.present(scene: .mastodonPrivacyPolicies(viewModel: viewModel), from: self, transition: .show)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonServerRulesViewController: OnboardingViewControllerAppearance { }

// MARK: - UITableViewDelegate
extension MastodonServerRulesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let wrapper = UIView()

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = MastodonPickServerViewController.subTitleFont
        label.textColor = Asset.Colors.Label.primary.color
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = L10n.Scene.ServerRules.subtitle(viewModel.domain)
        wrapper.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            wrapper.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            wrapper.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
        ])

        return wrapper
    }
}
