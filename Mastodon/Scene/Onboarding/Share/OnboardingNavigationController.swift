//
//  OnboardingNavigationController.swift
//  Mastodon
//
//  Created by MainasuK on 2021-12-31.
//

import UIKit

final class OnboardingNavigationController: AdaptiveStatusBarStyleNavigationController {
    
    private(set) lazy var gradientBorderView = GradientBorderView(frame: view.bounds)
    
}

extension OnboardingNavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradientBorderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientBorderView)
        NSLayoutConstraint.activate([
            gradientBorderView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientBorderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientBorderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientBorderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        updateBorderViewDisplay()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

    }
    
}

extension OnboardingNavigationController {
    
    private func updateBorderViewDisplay() {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            gradientBorderView.isHidden = true
        default:
            gradientBorderView.isHidden = false
        }
    }
}
