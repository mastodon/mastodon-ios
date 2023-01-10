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
    
    private enum Constants {
        static let topAnchorInset: CGFloat = 20
    }
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private(set) lazy var viewModel = WelcomeViewModel(context: context)
    
    let welcomeIllustrationView = WelcomeIllustrationView()
    
    private(set) lazy var dismissBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(WelcomeViewController.dismissBarButtonItemDidPressed(_:)))
    
    let buttonContainer = UIStackView()
    let educationPages: [WelcomeContentPage] = [.whatIsMastodon, .mastodonIsLikeThat, .howDoIPickAServer]
    
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
    
    private(set) lazy var signInButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = WelcomeViewController.actionButtonPadding
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        button.setTitle(L10n.Scene.Welcome.logIn, for: .normal)
        let titleColor: UIColor = UIColor.white.withAlphaComponent(0.9)
        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(titleColor.withAlphaComponent(0.3), for: .highlighted)
        return button
    }()
    
    private(set) lazy var pageCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSize(width: self.view.frame.width, height: 400)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = nil
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.register(WelcomeContentCollectionViewCell.self, forCellWithReuseIdentifier: WelcomeContentCollectionViewCell.identifier)

        return collectionView
    }()

    private(set) var pageControl: UIPageControl = {
        let pageControl = UIPageControl(frame: .zero)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        preferredContentSize = CGSize(width: 547, height: 678)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        view.overrideUserInterfaceStyle = .light
        
        setupOnboardingAppearance()
        
        view.addSubview(welcomeIllustrationView)
        welcomeIllustrationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            welcomeIllustrationView.topAnchor.constraint(equalTo: view.topAnchor),
            welcomeIllustrationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: welcomeIllustrationView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: welcomeIllustrationView.bottomAnchor)
        ])
        
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
        
        signUpButton.addTarget(self, action: #selector(signUpButtonDidClicked(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInButtonDidClicked(_:)), for: .touchUpInside)
        
        pageCollectionView.delegate = self
        pageCollectionView.dataSource = self
        view.addSubview(pageCollectionView)

        pageControl.numberOfPages = self.educationPages.count
        pageControl.addTarget(self, action: #selector(WelcomeViewController.pageControlDidChange(_:)), for: .valueChanged)
        view.addSubview(pageControl)

        let scrollView = pageCollectionView as UIScrollView
        scrollView.delegate = self
        
        NSLayoutConstraint.activate([
            pageCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: computedTopAnchorInset),
            pageCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: pageCollectionView.trailingAnchor),
            pageControl.topAnchor.constraint(equalTo: pageCollectionView.bottomAnchor, constant: 16),

            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: pageControl.trailingAnchor),
            buttonContainer.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 16),
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
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        view.layoutIfNeeded()
        
        setupIllustrationLayout()
        setupButtonShadowView()

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSize(width: self.view.frame.width, height: 400)

        pageCollectionView.setCollectionViewLayout(flowLayout, animated: true)
    }
    
    private var computedTopAnchorInset: CGFloat {
        (navigationController?.navigationBar.bounds.height ?? UINavigationBar().bounds.height) + Constants.topAnchorInset
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

    //MARK: - Actions
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

    @objc
    private func pageControlDidChange(_ sender: UIPageControl) {
        let item = sender.currentPage
        let indexPath = IndexPath(item: item, section: 0)

        pageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension WelcomeViewController: OnboardingViewControllerAppearance {}

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

//MARK: - UIScrollViewDelegate
extension WelcomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.x
        welcomeIllustrationView.update(contentOffset: contentOffset)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
}

//MARK: - UICollectionViewDelegate
extension WelcomeViewController: UICollectionViewDelegate { }

//MARK: - UICollectionViewDataSource
extension WelcomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        educationPages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WelcomeContentCollectionViewCell.identifier, for: indexPath) as? WelcomeContentCollectionViewCell else { fatalError("WTF? Wrong cell?") }

        let page = educationPages[indexPath.item]
        cell.update(with: page)

        return cell
    }
}
