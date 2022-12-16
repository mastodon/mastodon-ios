//
//  PrivacyTableViewController.swift
//  Mastodon
//
//  Created by Nathan Mattes on 15.12.22.
//

import UIKit
import MastodonCore
import MastodonSDK
import SafariServices

enum PrivacyRow {
    case iOSApp
    case server(domain: String)

    var url: URL? {
        switch self {
            case .iOSApp:
                return URL(string: "https://joinmastodon.org/ios/privacy")
            case .server(let domain):
                return URL(string: "https://\(domain)/privacy-policy")
        }
    }

    var title: String {
        switch self {
            case .iOSApp:
                return "Privacy Policy - Mastodon for iOS"
            case .server(let domain):
                return "Privacy Policy - \(domain)"
        }
    }
}

class PrivacyTableViewController: UIViewController, NeedsDependency {

    var context: AppContext!
    var coordinator: SceneCoordinator!

    private let tableView: UITableView
    let viewModel: PrivacyViewModel

    init(context: AppContext, coordinator: SceneCoordinator, viewModel: PrivacyViewModel) {

        self.context = context
        self.coordinator = coordinator

        self.viewModel = viewModel

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(PrivacyTableViewCell.self, forCellReuseIdentifier: PrivacyTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(tableView)
        setupConstraints()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "I agree", style: .done, target: self, action: #selector(PrivacyTableViewController.nextButtonPressed(_:)))
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

extension PrivacyTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PrivacyTableViewCell.reuseIdentifier, for: indexPath) as? PrivacyTableViewCell else { fatalError("Wrong cell?") }

        let row = viewModel.rows[indexPath.row]

        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.text = row.title

        cell.contentConfiguration = contentConfiguration

        return cell
    }
}

extension PrivacyTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = viewModel.rows[indexPath.row]
        guard let url = row.url else { return }

        _ = coordinator.present(scene: .safari(url: url), from: self, transition: .safariPresent(animated: true))
    }
}
