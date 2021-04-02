//
//  MastodonPickServerViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import os.log
import UIKit
import Combine

final class MastodonPickServerViewController: UIViewController, NeedsDependency {
    
    private var disposeBag = Set<AnyCancellable>()
    private var tableViewObservation: NSKeyValueObservation?
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonPickServerViewModel!
    
    private var expandServerDomainSet = Set<String>()
    
    private let emptyStateView = PickServerEmptyStateView()
    private let emptyStateViewHPadding: CGFloat = 4 // UIView's readableContentGuide is 4pt smaller then UITableViewCell's
    let tableViewTopPaddingView = UIView()      // fix empty state view background display when tableView bounce scrolling
    var tableViewTopPaddingViewHeightLayoutConstraint: NSLayoutConstraint!
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(PickServerTitleCell.self, forCellReuseIdentifier: String(describing: PickServerTitleCell.self))
        tableView.register(PickServerCategoriesCell.self, forCellReuseIdentifier: String(describing: PickServerCategoriesCell.self))
        tableView.register(PickServerSearchCell.self, forCellReuseIdentifier: String(describing: PickServerSearchCell.self))
        tableView.register(PickServerCell.self, forCellReuseIdentifier: String(describing: PickServerCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    let nextStepButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    deinit {
        tableViewObservation = nil
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonPickServerViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        defer { setupNavigationBarBackgroundView() }
        
        view.addSubview(nextStepButton)
        NSLayoutConstraint.activate([
            nextStepButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: MastodonPickServerViewController.actionButtonMargin),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: nextStepButton.trailingAnchor, constant: MastodonPickServerViewController.actionButtonMargin),
            nextStepButton.heightAnchor.constraint(equalToConstant: MastodonPickServerViewController.actionButtonHeight).priority(.defaultHigh),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: nextStepButton.bottomAnchor, constant: WelcomeViewController.viewBottomPaddingHeight),
        ])
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: emptyStateViewHPadding),
            emptyStateView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -emptyStateViewHPadding),
            nextStepButton.topAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: 21),
        ])
    
        // fix AutoLayout warning when observe before view appear
        viewModel.viewWillAppear
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.tableViewObservation = self.tableView.observe(\.contentSize, options: [.initial, .new]) { [weak self] tableView, _ in
                    guard let self = self else { return }
                    self.updateEmptyStateViewLayout()
                }
            }
            .store(in: &disposeBag)
        
        tableViewTopPaddingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableViewTopPaddingView)
        tableViewTopPaddingViewHeightLayoutConstraint = tableViewTopPaddingView.heightAnchor.constraint(equalToConstant: 0.0).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            tableViewTopPaddingView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            tableViewTopPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewTopPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewTopPaddingViewHeightLayoutConstraint,
        ])
        tableViewTopPaddingView.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextStepButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 7),
        ])
        
        switch viewModel.mode {
        case .signIn:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.signIn, for: .normal)
        case .signUp:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
        }
        nextStepButton.addTarget(self, action: #selector(nextStepButtonDidClicked(_:)), for: .touchUpInside)
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            pickServerCategoriesCellDelegate: self,
            pickServerSearchCellDelegate: self,
            pickServerCellDelegate: self
        )
        
        viewModel
            .selectedServer
            .map { $0 != nil }
            .assign(to: \.isEnabled, on: nextStepButton)
            .store(in: &disposeBag)
        
        viewModel.error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                let alertController = UIAlertController(for: error, title: "Error", preferredStyle: .alert)
                let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                alertController.addAction(okAction)
                self.coordinator.present(
                    scene: .alertController(alertController: alertController),
                    from: nil,
                    transition: .alertController(animated: true, completion: nil)
                )
            }
            .store(in: &disposeBag)
        
        viewModel
            .authenticated
            .flatMap { [weak self] (domain, user) -> AnyPublisher<Result<Bool, Error>, Never> in
                guard let self = self else { return Just(.success(false)).eraseToAnyPublisher() }
                return self.context.authenticationService.activeMastodonUser(domain: domain, userID: user.id)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                case .success(let isActived):
                    assert(isActived)
                    self.dismiss(animated: true, completion: nil)
                }
            }
            .store(in: &disposeBag)
        
        viewModel.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticating in
                guard let self = self else { return }
                isAuthenticating ? self.nextStepButton.showLoading() : self.nextStepButton.stopLoading()
            }
            .store(in: &disposeBag)
        
        viewModel.emptyStateViewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .none:
                    self.emptyStateView.isHidden = true
                case .loading:
                    self.emptyStateView.isHidden = false
                    self.emptyStateView.networkIndicatorImageView.isHidden = true
                    self.emptyStateView.activityIndicatorView.startAnimating()
                    self.emptyStateView.infoLabel.isHidden = false
                    self.emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.findingServers
                    self.emptyStateView.infoLabel.textAlignment = self.traitCollection.layoutDirection == .rightToLeft ? .right : .left
                case .badNetwork:
                    self.emptyStateView.isHidden = false
                    self.emptyStateView.networkIndicatorImageView.isHidden = false
                    self.emptyStateView.activityIndicatorView.stopAnimating()
                    self.emptyStateView.infoLabel.isHidden = false
                    self.emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.badNetwork
                    self.emptyStateView.infoLabel.textAlignment = .center
                }
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear.send()
    }
    
    
}

extension MastodonPickServerViewController {
    
    @objc
    private func nextStepButtonDidClicked(_ sender: UIButton) {
        switch viewModel.mode {
        case .signIn:
            doSignIn()
        case .signUp:
            doSignUp()
        }
    }
    
    private func doSignIn() {
        guard let server = viewModel.selectedServer.value else { return }
        viewModel.isAuthenticating.send(true)
        context.apiService.createApplication(domain: server.domain)
            .tryMap { response -> MastodonPickServerViewModel.AuthenticateInfo in
                let application = response.value
                guard let info = MastodonPickServerViewModel.AuthenticateInfo(domain: server.domain, application: application) else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                return info
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.viewModel.isAuthenticating.send(false)
                
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign in fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    self.viewModel.error.send(error)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] info in
                guard let self = self else { return }
                let mastodonPinBasedAuthenticationViewModel = MastodonPinBasedAuthenticationViewModel(authenticateURL: info.authorizeURL)
                self.viewModel.authenticate(
                    info: info,
                    pinCodePublisher: mastodonPinBasedAuthenticationViewModel.pinCodePublisher
                )
                self.viewModel.mastodonPinBasedAuthenticationViewController = self.coordinator.present(
                    scene: .mastodonPinBasedAuthentication(viewModel: mastodonPinBasedAuthenticationViewModel),
                    from: nil,
                    transition: .modal(animated: true, completion: nil)
                )
            }
            .store(in: &disposeBag)
    }
    
    private func doSignUp() {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let server = viewModel.selectedServer.value else { return }
        viewModel.isAuthenticating.send(true)
        
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
                guard let authenticateInfo = AuthenticationViewModel.AuthenticateInfo(domain: server.domain, application: application) else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                return MastodonPickServerViewModel.SignUpResponseSecond(instance: response.instance, authenticateInfo: authenticateInfo)
            }
            .compactMap { [weak self] response -> AnyPublisher<MastodonPickServerViewModel.SignUpResponseThird, Error>? in
                guard let self = self else { return nil }
                let instance = response.instance
                let authenticateInfo = response.authenticateInfo
                return self.context.apiService.applicationAccessToken(
                    domain: server.domain,
                    clientID: authenticateInfo.clientID,
                    clientSecret: authenticateInfo.clientSecret
                )
                .map { MastodonPickServerViewModel.SignUpResponseThird(instance: instance, authenticateInfo: authenticateInfo, applicationToken: $0) }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.viewModel.isAuthenticating.send(false)
                
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
                    self.coordinator.present(scene: .mastodonServerRules(viewModel: mastodonServerRulesViewModel), from: self, transition: .show)
                } else {
                    let mastodonRegisterViewModel = MastodonRegisterViewModel(
                        domain: server.domain,
                        authenticateInfo: response.authenticateInfo,
                        instance: response.instance.value,
                        applicationToken: response.applicationToken.value
                    )
                    self.coordinator.present(scene: .mastodonRegister(viewModel: mastodonRegisterViewModel), from: nil, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
}

// MARK: - UITableViewDelegate
extension MastodonPickServerViewController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let offsetY = scrollView.contentOffset.y + scrollView.safeAreaInsets.top
        if offsetY < 0 {
            tableViewTopPaddingViewHeightLayoutConstraint.constant = abs(offsetY)
        } else {
            tableViewTopPaddingViewHeightLayoutConstraint.constant = 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource else { return 0 }
        let sections = diffableDataSource.snapshot().sectionIdentifiers
        let section = sections[section]
        switch section {
        case .header:
            return 20
        case .category:
            // Since category view has a blur shadow effect, its height need to be large than the actual height,
            // Thus we reduce the section header's height by 10, and make the category cell height 60+20(10 inset for top and bottom)
            return 10
        case .search:
            // Same reason as above
            return 10
        case .servers:
            return 0
        }
    }
    
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .categoryPicker:
            guard let cell = cell as? PickServerCategoriesCell else { return }
            guard let diffableDataSource = cell.diffableDataSource else { return }
            let snapshot = diffableDataSource.snapshot()
             
            let item = viewModel.selectCategoryItem.value
            guard let section = snapshot.indexOfSection(.main),
                  let row = snapshot.indexOfItem(item) else { return }
            cell.collectionView.selectItem(at: IndexPath(item: row, section: section), animated: false, scrollPosition: .centeredHorizontally)
        case .search:
            guard let cell = cell as? PickServerSearchCell else { return }
            cell.searchTextField.text = viewModel.searchText.value
        default:
            break
        }
    }
    
}

extension MastodonPickServerViewController {
    private func updateEmptyStateViewLayout() {
        guard let diffableDataSource = self.viewModel.diffableDataSource else { return }
        guard let indexPath = diffableDataSource.indexPath(for: .search) else { return }
        let rectInTableView = tableView.rectForRow(at: indexPath)
    
        emptyStateView.topPaddingViewTopLayoutConstraint.constant = rectInTableView.maxY
    }
}

// MARK: - PickServerCategoriesCellDelegate
extension MastodonPickServerViewController: PickServerCategoriesCellDelegate {
    func pickServerCategoriesCell(_ cell: PickServerCategoriesCell, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let diffableDataSource = cell.diffableDataSource else { return }
        let item = diffableDataSource.itemIdentifier(for: indexPath)
        viewModel.selectCategoryItem.value = item ?? .all
    }
}

// MARK: - PickServerSearchCellDelegate
extension MastodonPickServerViewController: PickServerSearchCellDelegate {
    func pickServerSearchCell(_ cell: PickServerSearchCell, searchTextDidChange searchText: String?) {
        viewModel.searchText.send(searchText ?? "")
    }
}

// MARK: - PickServerCellDelegate
extension MastodonPickServerViewController: PickServerCellDelegate {
    func pickServerCell(_ cell: PickServerCell, expandButtonPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .server(_, attribute) = item else { return }
        
        attribute.isExpand.toggle()
        tableView.beginUpdates()
        cell.updateExpandMode(mode: attribute.isExpand ? .expand : .collapse)
        tableView.endUpdates()
        
        // expand attribute change do not needs apply snapshot to diffable data source
        // but should I block the viewModel data binding during tableView.beginUpdates/endUpdates?
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonPickServerViewController: OnboardingViewControllerAppearance { }
