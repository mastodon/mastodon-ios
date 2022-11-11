//
//  MastodonLoginViewController.swift
//  Mastodon
//
//  Created by Nathan Mattes on 09.11.22.
//

import UIKit

protocol MastodonLoginViewControllerDelegate: AnyObject {
  func backButtonPressed(_ viewController: MastodonLoginViewController)
  func nextButtonPressed(_ viewController: MastodonLoginViewController)
}

class MastodonLoginViewController: UIViewController {

  // back-button, next-button (enabled if user selectes a server or url is valid
  // next-button does MastodonPickServerViewController.doSignIn()

  weak var delegate: MastodonLoginViewControllerDelegate?

  var contentView: MastodonLoginView {
    view as! MastodonLoginView
  }

  init() {
    super.init(nibName: nil, bundle: nil)

    navigationItem.hidesBackButton = true
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func loadView() {
    let loginView = MastodonLoginView()

    loginView.navigationActionView.nextButton.addTarget(self, action: #selector(MastodonLoginViewController.nextButtonPressed(_:)), for: .touchUpInside)
    loginView.navigationActionView.backButton.addTarget(self, action: #selector(MastodonLoginViewController.backButtonPressed(_:)), for: .touchUpInside)
    loginView.searchTextField.addTarget(self, action: #selector(MastodonLoginViewController.textfieldDidChange(_:)), for: .editingChanged)

    //TODO: Set tableView.delegate and tableView.dataSource

    view = loginView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    defer { setupNavigationBarBackgroundView() }
    setupOnboardingAppearance()
  }

  //MARK: - Actions

  @objc func backButtonPressed(_ sender: Any) {
    delegate?.backButtonPressed(self)
  }

  @objc func nextButtonPressed(_ sender: Any) {
    delegate?.nextButtonPressed(self)
  }

  @objc func login(_ sender: Any) {
//    guard let server = viewModel.selectedServer.value else { return }
//    authenticationViewModel.isAuthenticating.send(true)
//    context.apiService.createApplication(domain: server.domain)
//      .tryMap { response -> AuthenticationViewModel.AuthenticateInfo in
//        let application = response.value
//        guard let info = AuthenticationViewModel.AuthenticateInfo(
//          domain: server.domain,
//          application: application,
//          redirectURI: response.value.redirectURI ?? APIService.oauthCallbackURL
//        ) else {
//          throw APIService.APIError.explicit(.badResponse)
//        }
//        return info
//      }
//      .receive(on: DispatchQueue.main)
//      .sink { [weak self] completion in
//        guard let self = self else { return }
//        self.authenticationViewModel.isAuthenticating.send(false)
//
//        switch completion {
//          case .failure(let error):
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign in fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//            self.viewModel.error.send(error)
//          case .finished:
//            break
//        }
//      } receiveValue: { [weak self] info in
//        guard let self = self else { return }
//        let authenticationController = MastodonAuthenticationController(
//          context: self.context,
//          authenticateURL: info.authorizeURL
//        )
//
//        self.mastodonAuthenticationController = authenticationController
//        authenticationController.authenticationSession?.presentationContextProvider = self
//        authenticationController.authenticationSession?.start()
//
//        self.authenticationViewModel.authenticate(
//          info: info,
//          pinCodePublisher: authenticationController.pinCodePublisher
//        )
//      }
//      .store(in: &disposeBag)
  }

  @objc func textfieldDidChange(_ textField: UITextField) {
    print(textField.text ?? "---")
  }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonLoginViewController: OnboardingViewControllerAppearance { }


