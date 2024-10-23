//
//  ProfilePagingViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import UIKit
import Combine
import XLPagerTabStrip
import TabBarPager
import MastodonAsset
import MastodonCore
import MastodonUI

protocol ProfilePagingViewControllerDelegate: AnyObject {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController customScrollViewContainerController: ScrollViewContainer, atIndex index: Int)
}

final class ProfilePagingViewController: ButtonBarPagerTabStripViewController, TabBarPageViewController {
    
    weak var tabBarPageViewDelegate: TabBarPageViewDelegate?
    weak var pagingDelegate: ProfilePagingViewControllerDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfilePagingViewModel?
    
    let buttonBarShadowView = UIView()
    private var buttonBarShadowAlpha: CGFloat = 0.0

    // MARK: - TabBarPageViewController
    
    var currentPage: TabBarPage? {
        return viewModel?.viewControllers[currentIndex]
    }
    
    var currentPageIndex: Int? {
        currentIndex
    }
    
    // MARK: - ButtonBarPagerTabStripViewController
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return viewModel?.viewControllers ?? []
    }
    
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        
        guard indexWasChanged, let viewModel = viewModel else { return }
        let page = viewModel.viewControllers[toIndex]
        tabBarPageViewDelegate?.pageViewController(self, didPresentingTabBarPage: page, at: toIndex)
    }
    
    // make key commands works
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        // configure style before viewDidLoad
        settings.style.buttonBarBackgroundColor = .systemBackground
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.buttonBarItemsShouldFillAvailableWidth = false   // alignment from leading to trailing
        settings.style.selectedBarHeight = 3
        settings.style.selectedBarBackgroundColor = Asset.Colors.Label.primary.color
        settings.style.buttonBarItemFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard let _ = self else { return }
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = Asset.Colors.Label.secondary.color
            newCell?.label.textColor = Asset.Colors.Label.primary.color
        }
    
        super.viewDidLoad()
        
        updateBarButtonInsets()
        
        if let buttonBarView = self.buttonBarView {
            buttonBarShadowView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(buttonBarShadowView, belowSubview: buttonBarView)
            buttonBarView.backgroundColor = .systemBackground
            buttonBarShadowView.pinTo(to: buttonBarView)
            
            viewModel?.$needsSetupBottomShadow
                .receive(on: DispatchQueue.main)
                .sink { [weak self] needsSetupBottomShadow in
                    guard let self = self else { return }
                    self.setupBottomShadow()
                }
                .store(in: &disposeBag)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupBottomShadow()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateBarButtonInsets()
    }

}

extension ProfilePagingViewController {
    
    private func updateBarButtonInsets() {
        let margin: CGFloat = {
            switch traitCollection.userInterfaceIdiom {
            case .phone:
                return ProfileViewController.containerViewMarginForCompactHorizontalSizeClass
            default:
                return traitCollection.horizontalSizeClass == .regular ?
                    ProfileViewController.containerViewMarginForRegularHorizontalSizeClass :
                    ProfileViewController.containerViewMarginForCompactHorizontalSizeClass
            }
        }()

        settings.style.buttonBarLeftContentInset = margin
        settings.style.buttonBarRightContentInset = margin
        barButtonLayout?.sectionInset.left = margin
        barButtonLayout?.sectionInset.right = margin
        barButtonLayout?.invalidateLayout()
    }
    
    private var barButtonLayout: UICollectionViewFlowLayout? {
        let layout = buttonBarView.collectionViewLayout as? UICollectionViewFlowLayout
        return layout
    }
    
    func setupBottomShadow() {
        guard let viewModel = viewModel, viewModel.needsSetupBottomShadow else {
            buttonBarShadowView.layer.shadowColor = nil
            buttonBarShadowView.layer.shadowRadius = 0
            return
        }
        buttonBarShadowView.layer.setupShadow(
            color: UIColor.black.withAlphaComponent(0.12),
            alpha: Float(buttonBarShadowAlpha),
            x: 0,
            y: 2,
            blur: 2,
            spread: 0,
            roundedRect: buttonBarShadowView.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: .zero
        )
    }
    
    func updateButtonBarShadow(progress: CGFloat) {
        let alpha = min(max(0, 10 * progress - 9), 1)
        if buttonBarShadowAlpha != alpha {
            buttonBarShadowAlpha = alpha
            setupBottomShadow()
            buttonBarShadowView.setNeedsLayout()
        }
    }
}

extension ProfilePagingViewController {
    
    var currentViewController: (UIViewController & TabBarPage)? {
        guard let viewModel = viewModel else { return nil }
        guard !viewModel.viewControllers.isEmpty,
              currentIndex < viewModel.viewControllers.count
        else { return nil }
        return viewModel.viewControllers[currentIndex]
    }
    
}

// workaround to fix tab man responder chain issue
extension ProfilePagingViewController {

    override var keyCommands: [UIKeyCommand]? {
        return currentViewController?.keyCommands
    }

    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        (currentViewController as? StatusTableViewControllerNavigateable)?.navigateKeyCommandHandlerRelay(sender)
    }

    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        (currentViewController as? StatusTableViewControllerNavigateable)?.statusKeyCommandHandlerRelay(sender)
    }
        
}
