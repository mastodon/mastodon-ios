//
//  SecondaryPlaceholderViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-29.
//

import UIKit
import Combine
import MastodonCore

final class SecondaryPlaceholderViewController: UIViewController {
    var disposeBag = Set<AnyCancellable>()
}

extension SecondaryPlaceholderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground(theme: ThemeService.shared.currentTheme)
    }
    
}

extension SecondaryPlaceholderViewController {
    private func setupBackground(theme: SystemTheme) {
        view.backgroundColor = theme.secondarySystemBackgroundColor
    }
}
