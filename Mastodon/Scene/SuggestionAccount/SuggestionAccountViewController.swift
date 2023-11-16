//
//  SuggestionAccountViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import Foundation
import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization
import MastodonSDK

class SuggestionAccountViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SuggestionAccountViewModel!

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(SuggestionAccountTableViewCell.self, forCellReuseIdentifier: SuggestionAccountTableViewCell.reuseIdentifier)
        // we're lazy, that's why we don't put the Footer in tableViewFooter
        tableView.register(SuggestionAccountTableViewFooter.self, forHeaderFooterViewReuseIdentifier: SuggestionAccountTableViewFooter.reuseIdentifier)
        tableView.contentInset.top = 16
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBarAppearance()
        defer { setupNavigationBarBackgroundView() }


        title = L10n.Scene.SuggestionAccount.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.done,
            target: self,
            action: #selector(SuggestionAccountViewController.doneButtonDidClick(_:))
        )

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            suggestionAccountTableViewCellDelegate: self
        )

        view.backgroundColor = .secondarySystemBackground
        tableView.backgroundColor = .secondarySystemBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }

    //MARK: - Actions

    @objc func doneButtonDidClick(_ sender: UIButton) {
        viewModel.delegate?.homeTimelineNeedRefresh.send()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension SuggestionAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewDiffableDataSource = viewModel.tableViewDiffableDataSource else { return }
        guard let item = tableViewDiffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .account(let record):
            let profileViewModel = ProfileViewModel(context: context, authContext: viewModel.authContext, optionalMastodonUser: record)
            _ = coordinator.present(
                scene: .profile(viewModel: profileViewModel),
                from: self,
                transition: .show
            )
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SuggestionAccountTableViewFooter.reuseIdentifier) as? SuggestionAccountTableViewFooter else {
            return nil
        }

        footerView.followAllButton.isEnabled = viewModel.records.isNotEmpty

        footerView.delegate = self
        return footerView
    }
}

// MARK: - AuthContextProvider
extension SuggestionAccountViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UserTableViewCellDelegate
extension SuggestionAccountViewController: UserTableViewCellDelegate {}

// MARK: - SuggestionAccountTableViewCellDelegate
extension SuggestionAccountViewController: SuggestionAccountTableViewCellDelegate { }


extension SuggestionAccountViewController: SuggestionAccountTableViewFooterDelegate {
    func followAll(_ footerView: SuggestionAccountTableViewFooter) {
        viewModel.followAllSuggestedAccounts(self) {
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }
    }
}

extension SuggestionAccountViewController: OnboardingViewControllerAppearance { }
