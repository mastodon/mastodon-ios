//
//  PrivacyTableViewController.swift
//  Mastodon
//
//  Created by Nathan Mattes on 15.12.22.
//

import UIKit
import SwiftUI
import MastodonCore
import MastodonSDK
import MastodonLocalization
import MastodonAsset

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
                return L10n.Scene.Privacy.Policy.ios
            case .server(let domain):
                return L10n.Scene.Privacy.Policy.server(domain)
        }
    }
}

class PrivacyTableViewController: UIViewController {

    private let coordinator: SceneCoordinator
    private let tableView: UITableView
    let viewModel: PrivacyViewModel

    init(coordinator: SceneCoordinator, viewModel: PrivacyViewModel) {
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.Scene.Privacy.Button.confirm, style: .done, target: self, action: #selector(PrivacyTableViewController.nextButtonPressed(_:)))

        title = L10n.Scene.Privacy.title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) won't been implemented, please don't use Storyboards.") }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always
        setupOnboardingAppearance()
    }

    @objc private func nextButtonPressed(_ sender: UIButton) {
        viewModel.didAccept()
    }
}

extension PrivacyTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PrivacyTableViewCell.reuseIdentifier, for: indexPath) as? PrivacyTableViewCell else {
            assertionFailure("unexpected cell dequeued")
            return UITableViewCell()
        }

        let row = viewModel.rows[indexPath.row]

        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.textProperties.color = Asset.Colors.Brand.blurple.color
        contentConfiguration.text = row.title
        cell.accessibilityTraits = [.button, .link]

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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let wrapper = UIView()
        let controller = UIHostingController(
            rootView: HeaderTextView(
                text: LocalizedStringKey(L10n.Scene.Privacy.description(viewModel.domain))
            )
        )
        guard let label = controller.view else { return nil }
        addChild(controller)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        controller.didMove(toParent: self)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            wrapper.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            wrapper.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 16)
        ])

        return wrapper
    }
}

extension PrivacyTableViewController: OnboardingViewControllerAppearance { }

private struct HeaderTextView: View {
    let text: LocalizedStringKey
    
    var body: some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Asset.Colors.Label.primary.swiftUIColor)
            .padding(.bottom, 16)
    }
}
