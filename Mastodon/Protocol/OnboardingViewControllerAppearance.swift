//
//  OnboardingViewControllerAppearance.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/25.
//

import UIKit

protocol OnboardingViewControllerAppearance: UIViewController {
    func setupOnboardingAppearance()
}

extension OnboardingViewControllerAppearance {
    func setupOnboardingAppearance() {
        overrideUserInterfaceStyle = .light
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color

        // set navigationBar transparent
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = barAppearance
        navigationController?.navigationBar.compactAppearance = barAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
        
        let backItem = UIBarButtonItem()
        backItem.title = "back"
        navigationController?.navigationBar.topItem?.backBarButtonItem = backItem
    }
}
