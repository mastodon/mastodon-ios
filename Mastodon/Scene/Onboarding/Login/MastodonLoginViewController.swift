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
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonLoginViewController: OnboardingViewControllerAppearance { }


