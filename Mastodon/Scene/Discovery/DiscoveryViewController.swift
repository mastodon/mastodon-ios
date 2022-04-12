//
//  DiscoveryViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import os.log
import UIKit
import Combine
import Tabman
import MastodonAsset

public class DiscoveryViewController: TabmanViewController, NeedsDependency {
    
    public static let containerViewMarginForRegularHorizontalSizeClass: CGFloat = 64
    public static let containerViewMarginForCompactHorizontalSizeClass: CGFloat = 16
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "DiscoveryViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private(set) lazy var viewModel = DiscoveryViewModel(
        context: context,
        coordinator: coordinator
    )
    
    let buttonBar: TMBar.ButtonBar = {
        let buttonBar = TMBar.ButtonBar()
        buttonBar.indicator.backgroundColor = Asset.Colors.Label.primary.color
        buttonBar.layout.contentInset = .zero
        return buttonBar
    }()
    
}

extension DiscoveryViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupAppearance(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupAppearance(theme: theme)
            }
            .store(in: &disposeBag)
        
        dataSource = viewModel
        addBar(
            buttonBar,
            dataSource: viewModel,
            at: .top
        )
        updateBarButtonInsets()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateBarButtonInsets()
    }

}

extension DiscoveryViewController {
    
    private func setupAppearance(theme: Theme) {
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        buttonBar.backgroundView.style = .flat(color: theme.systemBackgroundColor)
    }
    
    private func updateBarButtonInsets() {
        let margin: CGFloat = {
            switch traitCollection.userInterfaceIdiom {
            case .phone:
                return DiscoveryViewController.containerViewMarginForCompactHorizontalSizeClass
            default:
                return traitCollection.horizontalSizeClass == .regular ?
                DiscoveryViewController.containerViewMarginForRegularHorizontalSizeClass :
                DiscoveryViewController.containerViewMarginForCompactHorizontalSizeClass
            }
        }()
        
        buttonBar.layout.contentInset.left = margin
        buttonBar.layout.contentInset.right = margin
    }
    
}
