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
        gradientBorderView.pinToParent()
        
        updateBorderViewDisplay()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portraitOnPhone
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
