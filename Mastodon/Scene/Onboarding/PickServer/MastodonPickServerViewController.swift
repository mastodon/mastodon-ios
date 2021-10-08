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

final class MastodonPickServerViewController: UIViewController, NeedsDependency {
    
    private var disposeBag = Set<AnyCancellable>()
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
    let tableViewTopPaddingView = UIView()      // fix empty state view background display when tableView bounce scrolling
    var tableViewTopPaddingViewHeightLayoutConstraint: NSLayoutConstraint!
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(PickServerTitleCell.self, forCellReuseIdentifier: String(describing: PickServerTitleCell.self))
        tableView.register(PickServerCategoriesCell.self, forCellReuseIdentifier: String(describing: PickServerCategoriesCell.self))
        tableView.register(PickServerSearchCell.self, forCellReuseIdentifier: String(describing: PickServerSearchCell.self))
        tableView.register(PickServerCell.self, forCellReuseIdentifier: String(describing: PickServerCell.self))
        tableView.register(PickServerLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: PickServerLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        } else {
            // Fallback on earlier versions
        }
        return tableView
    }()
    
    let buttonContainer = UIView()
    let nextStepButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var buttonContainerBottomLayoutConstraint: NSLayoutConstraint!
    
    var mastodonAuthenticationController: MastodonAuthenticationController?
    
    deinit {
        tableViewObservation = nil
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonPickServerViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        defer { setupNavigationBarBackgroundView() }
        configureTitleLabel()
        configureMargin()

        #if DEBUG
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
        let children: [UIMenuElement] = [
            UIAction(title: "Dismiss", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] _ in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: nil)
            })
        ]
        navigationItem.rightBarButtonItem?.menu = UIMenu(title: "Debug Tool", image: nil, identifier: nil, options: [], children: children)
        #endif
        
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.preservesSuperviewLayoutMargins = true
        view.addSubview(buttonContainer)
        buttonContainerBottomLayoutConstraint = view.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: 0).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: buttonContainer.bottomAnchor, constant: WelcomeViewController.viewBottomPaddingHeight),
            buttonContainerBottomLayoutConstraint,
        ])
        
        view.addSubview(nextStepButton)
        NSLayoutConstraint.activate([
            nextStepButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            nextStepButton.leadingAnchor.constraint(equalTo: buttonContainer.layoutMarginsGuide.leadingAnchor),
            buttonContainer.layoutMarginsGuide.trailingAnchor.constraint(equalTo: nextStepButton.trailingAnchor),
            nextStepButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            nextStepButton.heightAnchor.constraint(equalToConstant: MastodonPickServerViewController.actionButtonHeight).priority(.defaultHigh),
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
        tableViewTopPaddingView.backgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainer.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 7),
        ])
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        emptyStateViewLeadingLayoutConstraint = emptyStateView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor)
        emptyStateViewTrailingLayoutConstraint = tableView.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateViewLeadingLayoutConstraint,
            emptyStateViewTrailingLayoutConstraint,
            buttonContainer.topAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: 21),
        ])
        view.sendSubviewToBack(emptyStateView)
        
        // update layout when keyboard show/dismiss
        let keyboardEventPublishers = Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow,
            KeyboardResponderService.shared.state,
            KeyboardResponderService.shared.endFrame
        )
        
        keyboardEventPublishers
            .sink { [weak self] keyboardEvents in
                guard let self = self else { return }
                let (isShow, state, endFrame) = keyboardEvents
                
                // guard external keyboard connected
                guard isShow, state == .dock, GCKeyboard.coalesced != nil else {
                    self.buttonContainerBottomLayoutConstraint.constant = WelcomeViewController.viewBottomPaddingHeight
                    return
                }
                
                let externalKeyboardToolbarHeight = self.view.frame.maxY - endFrame.minY
                guard externalKeyboardToolbarHeight > 0 else {
                    self.buttonContainerBottomLayoutConstraint.constant = WelcomeViewController.viewBottomPaddingHeight
                    return
                }
                
                UIView.animate(withDuration: 0.3) {
                    self.buttonContainerBottomLayoutConstraint.constant = externalKeyboardToolbarHeight + 16
                    self.view.layoutIfNeeded()
                }
            }
            .store(in: &disposeBag)
        
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
            self.coordinator.present(
                scene: .alertController(alertController: alertController),
                from: nil,
                transition: .alertController(animated: true, completion: nil)
            )
        }
        .store(in: &disposeBag)
        
        authenticationViewModel
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
                    // self.dismiss(animated: true, completion: nil)
                    self.coordinator.setup()
                }
            }
            .store(in: &disposeBag)
        
        authenticationViewModel.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticating in
                guard let self = self else { return }
                isAuthenticating ? self.nextStepButton.showLoading() : self.nextStepButton.stopLoading()
            }
            .store(in: &disposeBag)
        
        viewModel.emptyStateViewState
            .receive(on: RunLoop.main)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear.send()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupNavigationBarAppearance()
        updateEmptyStateViewLayout()
        configureTitleLabel()
        configureMargin()
    }
    
}

extension MastodonPickServerViewController {
    private func configureTitleLabel() {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }
        
        switch traitCollection.horizontalSizeClass {
        case .regular:
            navigationItem.largeTitleDisplayMode = .always
            navigationItem.title = L10n.Scene.ServerPicker.title.replacingOccurrences(of: "\n", with: " ")
        default:
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.title = nil
        }
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
        authenticationViewModel.isAuthenticating.send(true)
        context.apiService.createApplication(domain: server.domain)
            .tryMap { response -> AuthenticationViewModel.AuthenticateInfo in
                let application = response.value
                guard let info = AuthenticationViewModel.AuthenticateInfo(
                        domain: server.domain,
                        application: application,
                        redirectURI: response.value.redirectURI ?? MastodonAuthenticationController.callbackURL
                ) else {
                    throw APIService.APIError.explicit(.badResponse)
                }
                return info
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.authenticationViewModel.isAuthenticating.send(false)
                
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign in fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    self.viewModel.error.send(error)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] info in
                guard let self = self else { return }
                let authenticationController = MastodonAuthenticationController(
                    context: self.context,
                    authenticateURL: info.authorizeURL
                )
                
                self.mastodonAuthenticationController = authenticationController
                authenticationController.authenticationSession?.presentationContextProvider = self
                authenticationController.authenticationSession?.start()
                
                self.authenticationViewModel.authenticate(
                    info: info,
                    pinCodePublisher: authenticationController.pinCodePublisher
                )
            }
            .store(in: &disposeBag)
    }
    
    private func doSignUp() {
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
                return MastodonPickServerViewModel.SignUpResponseSecond(instance: response.instance, authenticateInfo: authenticateInfo)
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
                .map { MastodonPickServerViewModel.SignUpResponseThird(instance: instance, authenticateInfo: authenticateInfo, applicationToken: $0) }
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
                    self.coordinator.present(scene: .mastodonServerRules(viewModel: mastodonServerRulesViewModel), from: self, transition: .show)
                } else {
                    let mastodonRegisterViewModel = MastodonRegisterViewModel(
                        domain: server.domain,
                        context: self.context,
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
        
        switch traitCollection.horizontalSizeClass {
        case .regular:
            emptyStateViewLeadingLayoutConstraint.constant = MastodonPickServerViewController.viewEdgeMargin
            emptyStateViewTrailingLayoutConstraint.constant = MastodonPickServerViewController.viewEdgeMargin
        default:
            let margin = tableView.layoutMarginsGuide.layoutFrame.origin.x
            emptyStateViewLeadingLayoutConstraint.constant = margin
            emptyStateViewTrailingLayoutConstraint.constant = margin
        }
    }
    
    private func configureMargin() {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            let margin = MastodonPickServerViewController.viewEdgeMargin
            buttonContainer.layoutMargins = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
        default:
            buttonContainer.layoutMargins = .zero
        }
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

// MARK: - ASWebAuthenticationPresentationContextProviding
extension MastodonPickServerViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
