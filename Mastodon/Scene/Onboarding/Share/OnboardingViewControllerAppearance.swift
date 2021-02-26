//
//  OnboardingViewControllerAppearance.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/25.
//

import UIKit

protocol OnboardingViewControllerAppearance: UIViewController {
    static var viewBottomPaddingHeight: CGFloat { get }
    func setupOnboardingAppearance()
    func setupNavigationBarAppearance()
}

extension OnboardingViewControllerAppearance {
    
    static var actionButtonHeight: CGFloat { return 46 }
    static var actionButtonMargin: CGFloat { return 12 }
    static var viewBottomPaddingHeight: CGFloat { return 11 }
    
    func setupOnboardingAppearance() {
        overrideUserInterfaceStyle = .light
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color

        setupNavigationBarAppearance()
        
        let backItem = UIBarButtonItem()
        backItem.title = L10n.Common.Controls.Actions.back
        navigationItem.backBarButtonItem = backItem
    }
    
    func setupNavigationBarAppearance() {
        // use TransparentBackground so view push / dismiss will be more visual nature
        // please add opaque background for status bar manually if needs
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = barAppearance
        navigationController?.navigationBar.compactAppearance = barAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
    }
    
    func setupNavigationBarBackgroundView() {
        let navigationBarBackgroundView: UIView = {
            let view = UIView()
            view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
            return view
        }()
        
        navigationBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBarBackgroundView)
        NSLayoutConstraint.activate([
            navigationBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationBarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBarBackgroundView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
        ])
    }
    
}
