//
//  MastodonLoginViewController.swift
//  Mastodon
//
//  Created by Nathan Mattes on 09.11.22.
//

import UIKit
import MastodonSDK
import MastodonCore
import MastodonAsset
import Combine
import AuthenticationServices

protocol MastodonLoginViewControllerDelegate: AnyObject {
  func backButtonPressed(_ viewController: MastodonLoginViewController)
  func nextButtonPressed(_ viewController: MastodonLoginViewController)
}

enum MastodonLoginViewSection: Hashable {
  case servers
}

class MastodonLoginViewController: UIViewController {

  weak var delegate: MastodonLoginViewControllerDelegate?
  var dataSource: UITableViewDiffableDataSource<MastodonLoginViewSection, Mastodon.Entity.Server>?
  let viewModel: MastodonLoginViewModel
  let authenticationViewModel: AuthenticationViewModel
  var mastodonAuthenticationController: MastodonAuthenticationController?

  weak var appContext: AppContext?
  var disposeBag = Set<AnyCancellable>()

  var contentView: MastodonLoginView {
    view as! MastodonLoginView
  }

  init(appContext: AppContext, authenticationViewModel: AuthenticationViewModel) {

    viewModel = MastodonLoginViewModel(appContext: appContext)
    self.authenticationViewModel = authenticationViewModel
    self.appContext = appContext

    super.init(nibName: nil, bundle: nil)
    viewModel.delegate = self

    navigationItem.hidesBackButton = true
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func loadView() {
    let loginView = MastodonLoginView()

    loginView.navigationActionView.nextButton.addTarget(self, action: #selector(MastodonLoginViewController.nextButtonPressed(_:)), for: .touchUpInside)
    loginView.navigationActionView.backButton.addTarget(self, action: #selector(MastodonLoginViewController.backButtonPressed(_:)), for: .touchUpInside)
    loginView.searchTextField.addTarget(self, action: #selector(MastodonLoginViewController.textfieldDidChange(_:)), for: .editingChanged)
    loginView.tableView.delegate = self
    loginView.tableView.register(MastodonLoginServerTableViewCell.self, forCellReuseIdentifier: MastodonLoginServerTableViewCell.reuseIdentifier)
    loginView.navigationActionView.nextButton.isEnabled = false

    view = loginView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let dataSource = UITableViewDiffableDataSource<MastodonLoginViewSection, Mastodon.Entity.Server>(tableView: contentView.tableView) { [weak self] tableView, indexPath, itemIdentifier in
      guard let cell = tableView.dequeueReusableCell(withIdentifier: MastodonLoginServerTableViewCell.reuseIdentifier, for: indexPath) as? MastodonLoginServerTableViewCell,
            let self = self else {
        fatalError("Wrong cell")
      }

      let server = self.viewModel.filteredServers[indexPath.row]
      var configuration = cell.defaultContentConfiguration()
      configuration.text = server.domain

      cell.contentConfiguration = configuration
      cell.accessoryType = .disclosureIndicator

      if #available(iOS 16.0, *) {
        var backgroundConfiguration = cell.defaultBackgroundConfiguration()
        backgroundConfiguration.backgroundColor = Asset.Scene.Onboarding.textFieldBackground.color

        cell.backgroundConfiguration = backgroundConfiguration
      } else {
        cell.backgroundColor = .systemBackground
      }

      if self.viewModel.filteredServers.last == server {
        cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
      } else {
        cell.layer.masksToBounds = false
      }

      return cell
    }

    contentView.tableView.dataSource = dataSource
    self.dataSource = dataSource

    contentView.updateCorners()

    defer { setupNavigationBarBackgroundView() }
    setupOnboardingAppearance()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    viewModel.updateServers()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    contentView.searchTextField.becomeFirstResponder()
  }

  //MARK: - Actions

  @objc func backButtonPressed(_ sender: Any) {
    delegate?.backButtonPressed(self)
  }

  @objc func nextButtonPressed(_ sender: Any) {
    login(sender)
  }

  @objc func login(_ sender: Any) {
    guard let server = viewModel.selectedServer else { return }

    authenticationViewModel.isAuthenticating.send(true)
    appContext?.apiService.createApplication(domain: server.domain)
      .tryMap { response -> AuthenticationViewModel.AuthenticateInfo in
        let application = response.value
        guard let info = AuthenticationViewModel.AuthenticateInfo(
          domain: server.domain,
          application: application,
          redirectURI: response.value.redirectURI ?? APIService.oauthCallbackURL
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
//            self.viewModel.error.send(error)
            break
          case .finished:
            break
        }
      } receiveValue: { [weak self] info in
        guard let self, let appContext = self.appContext else { return }
        let authenticationController = MastodonAuthenticationController(
          context: appContext,
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

  @objc func textfieldDidChange(_ textField: UITextField) {
    viewModel.filterServers(withText: textField.text)


    if let text = textField.text,
       let domain = AuthenticationViewModel.parseDomain(from: text) {

      viewModel.selectedServer = .init(domain: domain, instance: .init(domain: domain))
      contentView.navigationActionView.nextButton.isEnabled = true
    } else {
      viewModel.selectedServer = nil
      contentView.navigationActionView.nextButton.isEnabled = false
    }
  }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonLoginViewController: OnboardingViewControllerAppearance { }

// MARK: - UITableViewDelegate
extension MastodonLoginViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let server = viewModel.filteredServers[indexPath.row]
    viewModel.selectedServer = server

    contentView.searchTextField.text = server.domain
    //TODO: @zeitschlag filter server list

    contentView.navigationActionView.nextButton.isEnabled = true
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

// MARK: - MastodonLoginViewModelDelegate
extension MastodonLoginViewController: MastodonLoginViewModelDelegate {
  func serversUpdated(_ viewModel: MastodonLoginViewModel) {
    var snapshot = NSDiffableDataSourceSnapshot<MastodonLoginViewSection, Mastodon.Entity.Server>()

    snapshot.appendSections([MastodonLoginViewSection.servers])
    snapshot.appendItems(viewModel.filteredServers)

    dataSource?.applySnapshot(snapshot, animated: false)

    OperationQueue.main.addOperation {
      let numberOfResults = viewModel.filteredServers.count
      self.contentView.updateCorners(numberOfResults: numberOfResults)
    }
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension MastodonLoginViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
