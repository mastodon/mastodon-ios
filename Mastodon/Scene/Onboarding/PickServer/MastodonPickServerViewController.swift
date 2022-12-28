//
//  MastodonPickServerViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import os.log
import UIKit
import Combine
import GameController
import AuthenticationServices
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI
import MastodonSDK

final class MastodonPickServerViewController: UIViewController, NeedsDependency {
    
    private var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()
    private var tableViewObservation: NSKeyValueObservation?
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonPickServerViewModel!
    private(set) lazy var authenticationViewModel = AuthenticationViewModel(
        context: context,
        coordinator: coordinator,
        isAuthenticationExist: false
    )
    
    private var expandServerDomainSet = Set<String>()
    
    private let emptyStateView = PickServerEmptyStateView()
    private var emptyStateViewLeadingLayoutConstraint: NSLayoutConstraint!
    private var emptyStateViewTrailingLayoutConstraint: NSLayoutConstraint!
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        return tableView
    }()

    let onboardingNextView: OnboardingNextView = {
        let onboardingNextView = OnboardingNextView()
        onboardingNextView.translatesAutoresizingMaskIntoConstraints = false
        onboardingNextView.backgroundColor = UIColor.secondarySystemBackground
        return onboardingNextView
    }()
    
    var mastodonAuthenticationController: MastodonAuthenticationController?

    let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = L10n.Scene.ServerPicker.Search.placeholder
        return searchController
    }()
}

extension MastodonPickServerViewController {    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        defer { setupNavigationBarBackgroundView() }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])
        
        view.addSubview(onboardingNextView)

        NSLayoutConstraint.activate([
            onboardingNextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingNextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: onboardingNextView.bottomAnchor),
        ])
        
        onboardingNextView
            .observe(\.bounds, options: [.initial, .new]) { [weak self] _, _ in
                guard let self = self else { return }
                let inset = self.onboardingNextView.frame.height
                self.viewModel.additionalTableViewInsets.bottom = inset
            }
            .store(in: &observations)

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        emptyStateViewLeadingLayoutConstraint = emptyStateView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor)
        emptyStateViewTrailingLayoutConstraint = tableView.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateViewLeadingLayoutConstraint,
            emptyStateViewTrailingLayoutConstraint,
            onboardingNextView.topAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: 21),
        ])
        view.sendSubviewToBack(emptyStateView)

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            pickServerServerSectionTableHeaderViewDelegate: self
        )
        
        KeyboardResponderService
            .configure(
                scrollView: tableView,
                layoutNeedsUpdate: viewModel.viewDidAppear.eraseToAnyPublisher(),
                additionalSafeAreaInsets: viewModel.$additionalTableViewInsets.eraseToAnyPublisher()
            )
            .store(in: &disposeBag)

        viewModel
            .selectedServer
            .map { $0 != nil }
            .assign(to: \.isEnabled, on: onboardingNextView.nextButton)
            .store(in: &disposeBag)

        Publishers.Merge(
            viewModel.error,
            authenticationViewModel.error
        )
        .compactMap { $0 }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] error in
            guard let self = self else { return }
            let alertController = UIAlertController(for: error, title: "Error", preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            _ = self.coordinator.present(
                scene: .alertController(alertController: alertController),
                from: nil,
                transition: .alertController(animated: true, completion: nil)
            )
        }
        .store(in: &disposeBag)

        authenticationViewModel
            .authenticated
            .asyncMap { domain, user -> Result<Bool, Error> in
                do {
                    let result = try await self.context.authenticationService.activeMastodonUser(domain: domain, userID: user.id)
                    return .success(result)
                } catch {
                    return .failure(error)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                case .success(let isActived):
                    assert(isActived)
                    // self.dismiss(animated: true, completion: nil)
                    self.coordinator.setup()
                }
            }
            .store(in: &disposeBag)

        authenticationViewModel.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticating in
                guard let self = self else { return }
                if isAuthenticating {
                    self.onboardingNextView.showLoading()
                } else {
                    self.onboardingNextView.stopLoading()
                }
            }
            .store(in: &disposeBag)

        viewModel.emptyStateViewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .none:
                    UIView.animate(withDuration: 0.3) {
                        self.emptyStateView.alpha = 0
                    }
                case .loading:
                    self.emptyStateView.alpha = 1
                    self.emptyStateView.networkIndicatorImageView.isHidden = true
                    self.emptyStateView.activityIndicatorView.startAnimating()
                    self.emptyStateView.infoLabel.isHidden = false
                    self.emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.findingServers
                    self.emptyStateView.infoLabel.textAlignment = self.traitCollection.layoutDirection == .rightToLeft ? .right : .left
                case .badNetwork:
                    self.emptyStateView.alpha = 1
                    self.emptyStateView.networkIndicatorImageView.isHidden = false
                    self.emptyStateView.activityIndicatorView.stopAnimating()
                    self.emptyStateView.infoLabel.isHidden = false
                    self.emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.badNetwork
                    self.emptyStateView.infoLabel.textAlignment = .center
                }
            }
            .store(in: &disposeBag)
        
        onboardingNextView.nextButton.addTarget(self, action: #selector(MastodonPickServerViewController.nextButtonDidPressed(_:)), for: .touchUpInside)

        title = L10n.Scene.ServerPicker.title

        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear.send()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
        viewModel.viewDidAppear.send()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupNavigationBarAppearance()
    }
    
}

extension MastodonPickServerViewController {

    @objc private func nextButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let server = viewModel.selectedServer.value else { return }
        authenticationViewModel.isAuthenticating.send(true)
        
        context.apiService.instance(domain: server.domain)
            .compactMap { [weak self] response -> AnyPublisher<MastodonPickServerViewModel.SignUpResponseFirst, Error>? in
                guard let self = self else { return nil }
                guard response.value.registrations != false else {
                    return Fail(error: AuthenticationViewModel.AuthenticationError.registrationClosed).eraseToAnyPublisher()
                }
                return self.context.apiService.createApplication(domain: server.domain)
                    .map { MastodonPickServerViewModel.SignUpResponseFirst(instance: response, application: $0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .tryMap { response -> MastodonPickServerViewModel.SignUpResponseSecond in
                let application = response.application.value
                guard let authenticateInfo = AuthenticationViewModel.AuthenticateInfo(
                        domain: server.domain,
                        application: application
                ) else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                return MastodonPickServerViewModel.SignUpResponseSecond(
                    instance: response.instance,
                    authenticateInfo: authenticateInfo
                )
            }
            .compactMap { [weak self] response -> AnyPublisher<MastodonPickServerViewModel.SignUpResponseThird, Error>? in
                guard let self = self else { return nil }
                let instance = response.instance
                let authenticateInfo = response.authenticateInfo
                return self.context.apiService.applicationAccessToken(
                    domain: server.domain,
                    clientID: authenticateInfo.clientID,
                    clientSecret: authenticateInfo.clientSecret,
                    redirectURI: authenticateInfo.redirectURI
                )
                .map {
                    MastodonPickServerViewModel.SignUpResponseThird(
                        instance: instance,
                        authenticateInfo: authenticateInfo,
                        applicationToken: $0
                    )
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.authenticationViewModel.isAuthenticating.send(false)
                
                switch completion {
                case .failure(let error):
                    self.viewModel.error.send(error)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if let rules = response.instance.value.rules, !rules.isEmpty {
                    // show server rules before register
                    let mastodonServerRulesViewModel = MastodonServerRulesViewModel(
                        domain: server.domain,
                        authenticateInfo: response.authenticateInfo,
                        rules: rules,
                        instance: response.instance.value,
                        applicationToken: response.applicationToken.value
                    )
                    _ = self.coordinator.present(scene: .mastodonServerRules(viewModel: mastodonServerRulesViewModel), from: self, transition: .show)
                } else {
                    let mastodonRegisterViewModel = MastodonRegisterViewModel(
                        context: self.context,
                        domain: server.domain,
                        authenticateInfo: response.authenticateInfo,
                        instance: response.instance.value,
                        applicationToken: response.applicationToken.value
                    )
                    _ = self.coordinator.present(scene: .mastodonRegister(viewModel: mastodonRegisterViewModel), from: nil, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
}

// MARK: - UITableViewDelegate
extension MastodonPickServerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        guard case .server = item else { return nil }
        
        if tableView.indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: false)
            viewModel.selectedServer.send(nil)
            return nil
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .server(server, _) = item else { return }
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        viewModel.selectedServer.send(server)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        viewModel.selectedServer.send(nil)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        let snapshot = diffableDataSource.snapshot()
        guard section < snapshot.numberOfSections else { return nil }
        let section = snapshot.sectionIdentifiers[section]
        
        switch section {
        case .servers:
            return viewModel.serverSectionHeaderView
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource else { return .leastNonzeroMagnitude }
        let snapshot = diffableDataSource.snapshot()
        guard section < snapshot.numberOfSections else { return .leastNonzeroMagnitude }
        let section = snapshot.sectionIdentifiers[section]
        
        switch section {
        case .servers:
            return PickServerServerSectionTableHeaderView.height
        default:
            return .leastNonzeroMagnitude
        }
    }
    
}

// MARK: - PickServerServerSectionTableHeaderViewDelegate
extension MastodonPickServerViewController: PickServerServerSectionTableHeaderViewDelegate {
    func pickServerServerSectionTableHeaderView(_ headerView: PickServerServerSectionTableHeaderView, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let diffableDataSource = headerView.diffableDataSource,
              let item = diffableDataSource.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) as? PickServerCategoryCollectionViewCell else { return }

        if case let .language(_) = item {
            viewModel.didPressMenuButton(in: cell)
        } else if case let .signupSpeed(_) = item {
            // gets also handled by button
            viewModel.didPressMenuButton(in: cell)
        } else {
            viewModel.selectCategoryItem.value = item
        }
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonPickServerViewController: OnboardingViewControllerAppearance { }

// MARK: - UISearchResultsUpdating

extension MastodonPickServerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.searchText.send(searchText)
    }
}
