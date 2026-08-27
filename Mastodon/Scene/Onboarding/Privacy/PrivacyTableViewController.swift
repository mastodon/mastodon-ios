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
import Combine
import SafariServices

enum PolicyRow {
    case iosAppPrivacy
    case serverPrivacy(domain: String)
    case serverTermsOfService(domain: String, confirmedReachable: Bool)

    var url: URL? {
        switch self {
        case .iosAppPrivacy:
            return URL(string: "https://joinmastodon.org/ios/privacy")
        case .serverPrivacy(let domain):
            return URL(string: "https://\(domain)/privacy-policy")
        case .serverTermsOfService(let domain, _):
            return URL(string: "\(URL.httpScheme(domain: domain))://" + domain + "/terms-of-service")
        }
    }

    var title: String {
        switch self {
        case .iosAppPrivacy:
                return L10n.Scene.Privacy.Policy.ios
        case .serverPrivacy(let domain):
                return L10n.Scene.Privacy.Policy.server(domain)
        case .serverTermsOfService(let domain, let fetched):
            if fetched {
                return L10n.Scene.Privacy.Policy.termsOfService(domain)
            } else {
                return "..."
            }
        }
    }
}

class PolicyTableViewController: UIViewController {

    private let coordinator: SceneCoordinator
    private let tableView: UITableView
    let viewModel: PolicyViewModel
    var disposeBag = Set<AnyCancellable>()

    init(coordinator: SceneCoordinator, viewModel: PolicyViewModel) {
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.Scene.Privacy.Button.confirm, style: .done, target: self, action: #selector(PolicyTableViewController.nextButtonPressed(_:)))
        
        title = L10n.Scene.Privacy.title
        
        viewModel.$sections.receive(on: DispatchQueue.main)
            .sink { [weak self] newSections in
                self?.title = newSections.count > 1 ? L10n.Scene.Privacy.termsOfServiceTitle : L10n.Scene.Privacy.title
                self?.tableView.reloadData()
            }
            .store(in: &disposeBag)
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

extension PolicyTableViewController: UITableViewDataSource {
    
    private func rows(forSection sectionIndex: Int) -> [PolicyRow] {
        let section = viewModel.sections[sectionIndex]
        switch section {
        case .termsOfService(let rows), .privacy(let rows):
            return rows
        }
    }
    
    private func row(at indexPath: IndexPath) -> PolicyRow {
        return rows(forSection: indexPath.section)[indexPath.row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows(forSection: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PrivacyTableViewCell.reuseIdentifier, for: indexPath) as? PrivacyTableViewCell else { fatalError("Wrong cell?") }

        let row = row(at: indexPath)
        
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.textProperties.color = Asset.Colors.Brand.blurple.color
        contentConfiguration.text = row.title
        cell.accessibilityTraits = [.button, .link]

        cell.contentConfiguration = contentConfiguration

        return cell
    }
}

extension PolicyTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = row(at: indexPath)
        guard let url = row.url else { return }

        if UserDefaults.shared.preferredUsingDefaultBrowser {
            UIApplication.shared.open(url)
        } else {
            let safariVC = SFSafariViewController(url: url)
            safariVC.modalPresentationCapturesStatusBarAppearance = true
            present(safariVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionItem = viewModel.sections[section]
        
        let wrapper = UIView()
        let controller = UIHostingController(
            rootView: HeaderTextView(
                title: section == 0 ? nil : LocalizedStringKey(sectionItem.title),
                text: LocalizedStringKey(sectionItem.description(viewModel.domain) ?? "")
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

extension PolicyTableViewController: OnboardingViewControllerAppearance { }

private struct HeaderTextView: View {
    let title: LocalizedStringKey?
    let text: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            if let title {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Asset.Colors.Label.primary.swiftUIColor)
                    .font(.title)
                    .padding(.bottom, 16)
            }
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Asset.Colors.Label.primary.swiftUIColor)
                .padding(.bottom, 16)
                .padding(.leading, 5)
        }
    }
}
