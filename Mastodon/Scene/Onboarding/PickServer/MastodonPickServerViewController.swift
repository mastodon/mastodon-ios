//
//  MastodonPickServerViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import Combine
import OSLog
import MastodonSDK

final class MastodonPickServerViewController: UIViewController, NeedsDependency {
    
    private var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonPickServerViewModel!
    
    private var isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    
    private var expandServerDomainSet = Set<String>()
    
    enum Section: CaseIterable {
        case title
        case categories
        case search
        case serverList
    }

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
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextStepButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 7)
        ])
        
        switch viewModel.mode {
        case .signIn:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.signIn, for: .normal)
        case .signUp:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
        }
        nextStepButton.addTarget(self, action: #selector(nextStepButtonDidClicked(_:)), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        viewModel
            .searchedServers
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] servers in
                self?.tableView.beginUpdates()
                self?.tableView.reloadSections(IndexSet(integer: 3), with: .automatic)
                self?.tableView.endUpdates()
                if let selectedServer = self?.viewModel.selectedServer.value, servers.contains(selectedServer) {
                    // Previously selected server is still in the list, do nothing
                } else {
                    // Previously selected server is not in the updated list, reset the selectedServer's value
                    self?.viewModel.selectedServer.send(nil)
                }
            }
            .store(in: &disposeBag)
        
        viewModel
            .selectedServer
            .map {
                $0 != nil
            }
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
        
        isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticating in
                guard let self = self else { return }
                isAuthenticating ? self.nextStepButton.showLoading() : self.nextStepButton.stopLoading()
            }
            .store(in: &disposeBag)
        
        viewModel.fetchAllServers()
    }
    
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
        isAuthenticating.send(true)
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
                self.isAuthenticating.send(false)
                
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
        isAuthenticating.send(true)
        
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
                self.isAuthenticating.send(false)
                
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

extension MastodonPickServerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let category = Section.allCases[section]
        switch category {
        case .title:
            return 20
        case .categories:
            // Since category view has a blur shadow effect, its height need to be large than the actual height,
            // Thus we reduce the section header's height by 10, and make the category cell height 60+20(10 inset for top and bottom)
            return 10
        case .search:
            // Same reason as above
            return 10
        case .serverList:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: false)
            viewModel.selectedServer.send(nil)
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        viewModel.selectedServer.send(viewModel.searchedServers.value[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        viewModel.selectedServer.send(nil)
    }
}

extension MastodonPickServerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Self.Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Self.Section.allCases[section]
        switch section {
        case .title,
             .categories,
             .search:
            return 1
        case .serverList:
            return viewModel.searchedServers.value.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = Self.Section.allCases[indexPath.section]
        switch section {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerTitleCell.self), for: indexPath) as! PickServerTitleCell
            return cell
        case .categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCategoriesCell.self), for: indexPath) as! PickServerCategoriesCell
            cell.dataSource = self
            cell.delegate = self
            return cell
        case .search:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerSearchCell.self), for: indexPath) as! PickServerSearchCell
            cell.delegate = self
            return cell
        case .serverList:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCell.self), for: indexPath) as! PickServerCell
            let server = viewModel.searchedServers.value[indexPath.row]
            cell.server = server
            if expandServerDomainSet.contains(server.domain) {
                cell.mode = .expand
            } else {
                cell.mode = .collapse
            }
            if server == viewModel.selectedServer.value {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
            
            cell.delegate = self
            return cell
        }
    }
}

extension MastodonPickServerViewController: PickServerCellDelegate {
    func pickServerCell(modeChange server: Mastodon.Entity.Server, newMode: PickServerCell.Mode, updates: (() -> Void)) {
        if newMode == .collapse {
            expandServerDomainSet.remove(server.domain)
        } else {
            expandServerDomainSet.insert(server.domain)
        }
        
        tableView.beginUpdates()
        updates()
        tableView.endUpdates()
        
        if newMode == .expand, let modeChangeIndex = self.viewModel.searchedServers.value.firstIndex(where: { $0 == server }), self.tableView.indexPathsForVisibleRows?.last?.row == modeChangeIndex {
            self.tableView.scrollToRow(at: IndexPath(row: modeChangeIndex, section: 3), at: .bottom, animated: true)
        }
    }
}

extension MastodonPickServerViewController: PickServerSearchCellDelegate {
    func pickServerSearchCell(didChange searchText: String?) {
        viewModel.searchText.send(searchText)
    }
}

extension MastodonPickServerViewController: PickServerCategoriesDataSource, PickServerCategoriesDelegate {
    func numberOfCategories() -> Int {
        return viewModel.categories.count
    }
    
    func category(at index: Int) -> MastodonPickServerViewModel.Category {
        return viewModel.categories[index]
    }
    
    func selectedIndex() -> Int {
        return viewModel.selectCategoryIndex.value
    }
    
    func pickServerCategoriesCell(didSelect index: Int) {
        return viewModel.selectCategoryIndex.send(index)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonPickServerViewController: OnboardingViewControllerAppearance { }
