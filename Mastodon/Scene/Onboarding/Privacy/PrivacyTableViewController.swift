//
//  PrivacyTableViewController.swift
//  Mastodon
//
//  Created by Nathan Mattes on 15.12.22.
//

import UIKit
import MastodonCore
import MastodonSDK

// https://joinmastodon.org/ios/privacy
// "\(server.domain)/privacy-policy"

class PrivacyTableViewController: UIViewController, NeedsDependency {

    var context: AppContext!
    var coordinator: SceneCoordinator!

    private let tableView: UITableView

    init(context: AppContext, coordinator: SceneCoordinator, server: Mastodon.Entity.Server) {

        self.context = context
        self.coordinator = coordinator

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(PrivacyTableViewCell.self, forCellReuseIdentifier: PrivacyTableViewCell.reuseIdentifier)
        tableView.register(OnboardingHeadlineTableViewCell.self, forCellReuseIdentifier: OnboardingHeadlineTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        view.addSubview(tableView)
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) won't been implemented, please don't use Storyboards.") }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    //MARK: - Actions
    @objc private func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @objc private func nextButtonPressed(_ sender: UIButton) {
//        let viewModel = MastodonRegisterViewModel(
//            context: context,
//            domain: viewModel.domain,
//            authenticateInfo: viewModel.authenticateInfo,
//            instance: viewModel.instance,
//            applicationToken: viewModel.applicationToken
//        )
//        _ = coordinator.present(scene: .mastodonRegister(viewModel: viewModel), from: self, transition: .show)
    }
}
