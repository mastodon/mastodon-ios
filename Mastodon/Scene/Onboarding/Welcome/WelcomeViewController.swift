//
//  WelcomeViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class WelcomeViewController: UIViewController, NeedsDependency {

  weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
  weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

  var disposeBag = Set<AnyCancellable>()
  var observations = Set<NSKeyValueObservation>()
  private(set) lazy var viewModel = WelcomeViewModel(context: context)

  let welcomeIllustrationView = WelcomeIllustrationView()

  private(set) lazy var dismissBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(WelcomeViewController.dismissBarButtonItemDidPressed(_:)))

  let buttonContainer = UIStackView()

  private(set) lazy var signUpButton: PrimaryActionButton = {
    let button = PrimaryActionButton()
    button.adjustsBackgroundImageWhenUserInterfaceStyleChanges = false
    button.contentEdgeInsets = WelcomeViewController.actionButtonPadding
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
    button.setTitle(L10n.Common.Controls.Actions.signUp, for: .normal)
    let backgroundImageColor: UIColor = .white
    let backgroundImageHighlightedColor: UIColor = UIColor(white: 0.8, alpha: 1.0)
    button.setBackgroundImage(.placeholder(color: backgroundImageColor), for: .normal)
    button.setBackgroundImage(.placeholder(color: backgroundImageHighlightedColor), for: .highlighted)
    button.setTitleColor(.black, for: .normal)
    return button
  }()
  let signUpButtonShadowView = UIView()

  private(set) lazy var signInButton: PrimaryActionButton = {
    let button = PrimaryActionButton()
    button.adjustsBackgroundImageWhenUserInterfaceStyleChanges = false
    button.contentEdgeInsets = WelcomeViewController.actionButtonPadding
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
    button.setTitle(L10n.Scene.Welcome.logIn, for: .normal)
    let backgroundImageColor = Asset.Scene.Welcome.signInButtonBackground.color
    let backgroundImageHighlightedColor = Asset.Scene.Welcome.signInButtonBackground.color.withAlphaComponent(0.8)
    button.setBackgroundImage(.placeholder(color: backgroundImageColor), for: .normal)
    button.setBackgroundImage(.placeholder(color: backgroundImageHighlightedColor), for: .highlighted)
    let titleColor: UIColor = UIColor.white.withAlphaComponent(0.9)
    button.setTitleColor(titleColor, for: .normal)
    return button
  }()
  let signInButtonShadowView = UIView()

  private(set) lazy var pageViewController: UIPageViewController = {
    let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    pageController.setViewControllers([WelcomeContentViewController(page: .whatIsMastodon)], direction: .forward, animated: false)
    return pageController
  }()
  var currentPage: WelcomeContentPage = .whatIsMastodon
  var currentPageOffset = 0
}

extension WelcomeViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    definesPresentationContext = true
    preferredContentSize = CGSize(width: 547, height: 678)

    navigationController?.navigationBar.prefersLargeTitles = true
    navigationItem.largeTitleDisplayMode = .never
    view.overrideUserInterfaceStyle = .light

    setupOnboardingAppearance()

    view.addSubview(welcomeIllustrationView)
    welcomeIllustrationView.translatesAutoresizingMaskIntoConstraints = false

    let bottomAnchorLayoutConstraint = welcomeIllustrationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

    NSLayoutConstraint.activate([
      welcomeIllustrationView.topAnchor.constraint(equalTo: view.topAnchor),
      welcomeIllustrationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: welcomeIllustrationView.trailingAnchor),
      bottomAnchorLayoutConstraint
    ])

    welcomeIllustrationView.bottomAnchorLayoutConstraint = bottomAnchorLayoutConstraint

    buttonContainer.axis = .vertical
    buttonContainer.spacing = 12
    buttonContainer.isLayoutMarginsRelativeArrangement = true

    buttonContainer.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(buttonContainer)
    NSLayoutConstraint.activate([
      buttonContainer.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
      buttonContainer.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
      view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
    ])

    signUpButton.translatesAutoresizingMaskIntoConstraints = false
    buttonContainer.addArrangedSubview(signUpButton)
    NSLayoutConstraint.activate([
      signUpButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
    ])
    signInButton.translatesAutoresizingMaskIntoConstraints = false
    buttonContainer.addArrangedSubview(signInButton)
    NSLayoutConstraint.activate([
      signInButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight).priority(.required - 1),
    ])

    signUpButtonShadowView.translatesAutoresizingMaskIntoConstraints = false
    buttonContainer.addSubview(signUpButtonShadowView)
    buttonContainer.sendSubviewToBack(signUpButtonShadowView)
    signUpButtonShadowView.pinTo(to: signUpButton)

    signInButtonShadowView.translatesAutoresizingMaskIntoConstraints = false
    buttonContainer.addSubview(signInButtonShadowView)
    buttonContainer.sendSubviewToBack(signInButtonShadowView)
    signInButtonShadowView.pinTo(to: signInButton)

    signUpButton.addTarget(self, action: #selector(signUpButtonDidClicked(_:)), for: .touchUpInside)
    signInButton.addTarget(self, action: #selector(signInButtonDidClicked(_:)), for: .touchUpInside)

    pageViewController.delegate = self
    pageViewController.dataSource = self
    addChild(pageViewController)
    pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pageViewController.view)
    pageViewController.didMove(toParent: self)




    let scrollviews = pageViewController.view.subviews.filter { type(of: $0).isSubclass(of: UIScrollView.self) }.compactMap { $0 as? UIScrollView }

    for scrollView in scrollviews {
      scrollView.delegate = self
    }

    NSLayoutConstraint.activate([
      pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: pageViewController.view.trailingAnchor),
      buttonContainer.topAnchor.constraint(equalTo: pageViewController.view.bottomAnchor, constant: 16),
    ])

    viewModel.$needsShowDismissEntry
      .receive(on: DispatchQueue.main)
      .sink { [weak self] needsShowDismissEntry in
        guard let self = self else { return }
        self.navigationItem.leftBarButtonItem = needsShowDismissEntry ? self.dismissBarButtonItem : nil
      }
      .store(in: &disposeBag)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    setupButtonShadowView()
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()

    var overlap: CGFloat = 5
    // shift illustration down for non-notch phone
    if view.safeAreaInsets.bottom == 0 {
      overlap += 56
    }
    welcomeIllustrationView.bottomAnchorLayoutConstraint?.constant = overlap
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    view.layoutIfNeeded()

    setupIllustrationLayout()
    setupButtonShadowView()
  }
}

extension WelcomeViewController {

  private func setupButtonShadowView() {
    signUpButtonShadowView.layer.setupShadow(
      color: .black,
      alpha: 0.25,
      x: 0,
      y: 1,
      blur: 2,
      spread: 0,
      roundedRect: signUpButtonShadowView.bounds,
      byRoundingCorners: .allCorners,
      cornerRadii: CGSize(width: 10, height: 10)
    )
    signInButtonShadowView.layer.setupShadow(
      color: .black,
      alpha: 0.25,
      x: 0,
      y: 1,
      blur: 2,
      spread: 0,
      roundedRect: signInButtonShadowView.bounds,
      byRoundingCorners: .allCorners,
      cornerRadii: CGSize(width: 10, height: 10)
    )
  }

  private func updateButtonContainerLayoutMargins(traitCollection: UITraitCollection) {
    switch traitCollection.userInterfaceIdiom {
      case .phone:
        buttonContainer.layoutMargins = UIEdgeInsets(
          top: 0,
          left: WelcomeViewController.actionButtonMargin,
          bottom: WelcomeViewController.viewBottomPaddingHeight,
          right: WelcomeViewController.actionButtonMargin
        )
      default:
        let margin = traitCollection.horizontalSizeClass == .regular ? WelcomeViewController.actionButtonMarginExtend : WelcomeViewController.actionButtonMargin
        buttonContainer.layoutMargins = UIEdgeInsets(
          top: 0,
          left: margin,
          bottom: WelcomeViewController.viewBottomPaddingHeightExtend,
          right: margin
        )
    }
  }

  private func setupIllustrationLayout() {
    welcomeIllustrationView.setup()
  }
}

extension WelcomeViewController {
  @objc
  private func signUpButtonDidClicked(_ sender: UIButton) {
    _ = coordinator.present(scene: .mastodonPickServer(viewMode: MastodonPickServerViewModel(context: context)), from: self, transition: .show)
  }

  @objc
  private func signInButtonDidClicked(_ sender: UIButton) {
    _ = coordinator.present(scene: .mastodonLogin, from: self, transition: .show)
  }

  @objc
  private func dismissBarButtonItemDidPressed(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }
}

// MARK: - OnboardingViewControllerAppearance
extension WelcomeViewController: OnboardingViewControllerAppearance {
    func setupNavigationBarAppearance() {
        // always transparent
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        navigationItem.compactScrollEdgeAppearance = barAppearance
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension WelcomeViewController: UIAdaptivePresentationControllerDelegate {

  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {

    // update button layout
    updateButtonContainerLayoutMargins(traitCollection: traitCollection)

    let navigationController = navigationController as? OnboardingNavigationController

    switch traitCollection.userInterfaceIdiom {
      case .phone:
        navigationController?.gradientBorderView.isHidden = true
        // make underneath view controller alive to fix layout issue due to view life cycle
        return .fullScreen
      default:
        switch traitCollection.horizontalSizeClass {
          case .compact:
            navigationController?.gradientBorderView.isHidden = true
            return .fullScreen
          default:
            navigationController?.gradientBorderView.isHidden = false
            return .formSheet
        }
    }
  }

  func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
    return nil
  }

  func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
    return false
  }
}

//MARK: - UIPageViewControllerDelegate

extension WelcomeViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard let currentViewController = pageViewController.viewControllers?.first as? WelcomeContentViewController else { return }

    currentPage = currentViewController.page

    if let pageIndex = WelcomeContentPage.allCases.firstIndex(of: currentPage) {
      let offset = Int(pageIndex) * Int(pageViewController.view.frame.width)
      currentPageOffset = offset
      welcomeIllustrationView.update(contentOffset: CGFloat(offset))
    }
  }
}

//MARK: - UIPageViewDataSource

extension WelcomeViewController: UIPageViewControllerDataSource {

  func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    WelcomeContentPage.allCases.firstIndex(of: currentPage) ?? 0
  }

  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return WelcomeContentPage.allCases.count
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let viewController = viewController as? WelcomeContentViewController else { return nil }

    let currentPage = viewController.page

    switch currentPage {
      case .whatIsMastodon:
        return nil
      case .mastodonIsLikeThat:
        return WelcomeContentViewController(page: .whatIsMastodon)
      case .howDoIPickAServer:
        return WelcomeContentViewController(page: .mastodonIsLikeThat)
    }
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let viewController = viewController as? WelcomeContentViewController else { return nil }

    let currentPage = viewController.page

    switch currentPage {
      case .whatIsMastodon:
        return WelcomeContentViewController(page: .mastodonIsLikeThat)
      case .mastodonIsLikeThat:
        return WelcomeContentViewController(page: .howDoIPickAServer)
      case .howDoIPickAServer:
        return nil
    }
  }
}

extension WelcomeViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let weirdScrollViewJumpingCorrectionFactor = pageViewController.view.frame.width
    let contentOffset = CGFloat(currentPageOffset) + scrollView.contentOffset.x - weirdScrollViewJumpingCorrectionFactor

    welcomeIllustrationView.update(contentOffset: contentOffset)
  }
}
