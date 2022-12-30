//
//  ReportViewControllerAppearance.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import MastodonAsset
import MastodonLocalization

protocol ReportViewControllerAppearance: UIViewController {
    func setupAppearance()
    func setupNavigationBarAppearance()
}

extension ReportViewControllerAppearance {
    
    
    func setupAppearance() {
        
        // title = L10n.Scene.Report.titleReport
        view.backgroundColor = Asset.Scene.Report.background.color

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
        navigationItem.compactScrollEdgeAppearance = barAppearance
    }
    
    func setupNavigationBarBackgroundView() {
        let navigationBarBackgroundView: UIView = {
            let view = UIView()
            view.backgroundColor = Asset.Scene.Report.background.color
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
