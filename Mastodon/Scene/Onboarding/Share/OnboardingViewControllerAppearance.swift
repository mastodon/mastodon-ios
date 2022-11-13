//
//  OnboardingViewControllerAppearance.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/25.
//

import UIKit
import MastodonAsset
import MastodonLocalization

protocol OnboardingViewControllerAppearance: UIViewController {
    static var viewBottomPaddingHeight: CGFloat { get }
    func setupOnboardingAppearance()
    func setupNavigationBarAppearance()
}

extension OnboardingViewControllerAppearance {
    
    static var actionButtonHeight: CGFloat { return 50 }
    static var actionButtonMargin: CGFloat { return 12 }
    static var actionButtonMarginExtend: CGFloat { return 80 }
    static var viewBottomPaddingHeight: CGFloat { return 11 }
    static var viewBottomPaddingHeightExtend: CGFloat { return 22 }

    // Typically assigned to the button's contentEdgeInsets. Ensures space around content, even when
    // content is large due to Dynamic Type.
    static var actionButtonPadding: UIEdgeInsets { return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) }
    
    static var largeTitleFont: UIFont {
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 28, weight: .bold))
    }
    
    static var largeTitleTextColor: UIColor {
        return Asset.Colors.Label.primary.color
    }
    
    static var subTitleFont: UIFont {
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
    }
    
    static var subTitleTextColor: UIColor {
        return Asset.Colors.Label.secondary.color
    }
    
    func setupOnboardingAppearance() {
        view.backgroundColor = Asset.Scene.Onboarding.background.color

        setupNavigationBarAppearance()
        
        let backItem = UIBarButtonItem(
            title: L10n.Common.Controls.Actions.back,
            style: .plain,
            target: nil,
            action: nil
        )
        navigationItem.backBarButtonItem = backItem
    }
    
    func setupNavigationBarAppearance() {
        // use TransparentBackground so view push / dismiss will be more visual nature
        // please add opaque background for status bar manually if needs
        
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = barAppearance
        } else {
            // Fallback on earlier versions
        }
    }
    
    func setupNavigationBarBackgroundView() {
        let navigationBarBackgroundView: UIView = {
            let view = UIView()
            view.backgroundColor = Asset.Scene.Onboarding.background.color
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

extension OnboardingViewControllerAppearance {
    static var viewEdgeMargin: CGFloat {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return .zero }
        return 20
//        let shortEdgeWidth = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
//        return shortEdgeWidth * 0.17 // magic
    }
}
