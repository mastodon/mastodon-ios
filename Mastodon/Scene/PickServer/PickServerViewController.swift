//
//  PickServerViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import Combine
import OSLog
import MastodonSDK

final class PickServerViewController: UIViewController, NeedsDependency {
    
    private var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: PickServerViewModel!
    
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
        let button = PrimaryActionButton(type: .system)
        button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
}

extension PickServerViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        
        view.addSubview(nextStepButton)
        NSLayoutConstraint.activate([
            nextStepButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 12),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: nextStepButton.trailingAnchor, constant: 12),
            view.bottomAnchor.constraint(equalTo: nextStepButton.bottomAnchor, constant: 34),
        ])
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextStepButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 7)
        ])
        
        switch viewModel.mode {
        case .SignIn:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.signIn, for: .normal)
        case .SignUp:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
        }
        nextStepButton.addTarget(self, action: #selector(nextStepButtonDidClicked(_:)), for: .touchUpInside)
        
        viewModel.tableView = tableView
        tableView.delegate = viewModel
        tableView.dataSource = viewModel
        
        viewModel
            .searchedServers
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] servers in
                self?.tableView.reloadSections(IndexSet(integer: 3), with: .automatic)
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
                let alertController = UIAlertController(error, preferredStyle: .alert)
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
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] (domain, user) -> AnyPublisher<Result<Bool, Error>, Never> in
                guard let self = self else { return Just(.success(false)).eraseToAnyPublisher() }
                return self.context.authenticationService.activeMastodonUser(domain: domain, userID: user.id)
            }
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                case .success(let isActived):
                    assert(isActived)
                    self.coordinator.setup()
                }
            }
            .store(in: &disposeBag)
        
        
        viewModel.fetchAllServers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @objc
    private func nextStepButtonDidClicked(_ sender: UIButton) {
        switch viewModel.mode {
        case .SignIn:
            doSignIn()
        case .SignUp:
            doSignUp()
        }
    }
    
    private func doSignIn() {
        guard let server = viewModel.selectedServer.value else { return }
        context.apiService.createApplication(domain: server.domain)
            .tryMap { response -> PickServerViewModel.AuthenticateInfo in
                let application = response.value
                guard let info = PickServerViewModel.AuthenticateInfo(domain: server.domain, application: application) else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                return info
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
//                self.viewModel.isAuthenticating.value = false
                
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
//        viewModel.isRegistering.value = true
        
        context.apiService.instance(domain: server.domain)
            .compactMap { [weak self] response -> AnyPublisher<PickServerViewModel.SignUpResponseFirst, Error>? in
                guard let self = self else { return nil }
                guard response.value.registrations != false else {
                    return Fail(error: AuthenticationViewModel.AuthenticationError.registrationClosed).eraseToAnyPublisher()
                }
                return self.context.apiService.createApplication(domain: server.domain)
                    .map { PickServerViewModel.SignUpResponseFirst(instance: response, application: $0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .tryMap { response -> PickServerViewModel.SignUpResponseSecond in
                let application = response.application.value
                guard let authenticateInfo = AuthenticationViewModel.AuthenticateInfo(domain: server.domain, application: application) else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                return PickServerViewModel.SignUpResponseSecond(instance: response.instance, authenticateInfo: authenticateInfo)
            }
            .compactMap { [weak self] response -> AnyPublisher<PickServerViewModel.SignUpResponseThird, Error>? in
                guard let self = self else { return nil }
                let instance = response.instance
                let authenticateInfo = response.authenticateInfo
                return self.context.apiService.applicationAccessToken(
                    domain: server.domain,
                    clientID: authenticateInfo.clientID,
                    clientSecret: authenticateInfo.clientSecret
                )
                .map { PickServerViewModel.SignUpResponseThird(instance: instance, authenticateInfo: authenticateInfo, applicationToken: $0) }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
//                self.viewModel.isRegistering.value = false
                
                switch completion {
                case .failure(let error):
                    self.viewModel.error.send(error)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let mastodonRegisterViewModel = MastodonRegisterViewModel(
                    domain: server.domain,
                    authenticateInfo: response.authenticateInfo,
                    instance: response.instance.value,
                    applicationToken: response.applicationToken.value
                )
                self.coordinator.present(scene: .mastodonRegister(viewModel: mastodonRegisterViewModel), from: self, transition: .show)
            }
            .store(in: &disposeBag)
    }
}
