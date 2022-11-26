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
        
        setupBackground(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackground(theme: theme)
            }
            .store(in: &disposeBag)
    }
    
}

extension SecondaryPlaceholderViewController {
    private func setupBackground(theme: Theme) {
        view.backgroundColor = theme.secondarySystemBackgroundColor
    }
}
