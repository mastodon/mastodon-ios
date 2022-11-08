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
import Pageboy
import MastodonAsset
import MastodonCore
import MastodonUI

public class DiscoveryViewController: TabmanViewController, NeedsDependency {
    
    public static let containerViewMarginForRegularHorizontalSizeClass: CGFloat = 64
    public static let containerViewMarginForCompactHorizontalSizeClass: CGFloat = 16
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "DiscoveryViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
        
    var viewModel: DiscoveryViewModel!
    
    private(set) lazy var buttonBar: TMBar.ButtonBar = {
        let buttonBar = TMBar.ButtonBar()
        buttonBar.backgroundView.style = .custom(view: buttonBarBackgroundView)
        buttonBar.layout.interButtonSpacing = 0
        buttonBar.layout.contentInset = .zero
        buttonBar.indicator.backgroundColor = Asset.Colors.Label.primary.color
        buttonBar.indicator.weight = .custom(value: 2)
        return buttonBar
    }()
    
    let buttonBarBackgroundView: UIView = {
        let view = UIView()
        let barBottomLine = UIView.separatorLine
        barBottomLine.backgroundColor = Asset.Colors.Label.secondary.color.withAlphaComponent(0.5)
        barBottomLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(barBottomLine)
        NSLayoutConstraint.activate([
            barBottomLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            barBottomLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            barBottomLine.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            barBottomLine.heightAnchor.constraint(equalToConstant: 2).priority(.required - 1),
        ])
        return view
    }()
    
    func customizeButtonBarAppearance() {
        // The implmention use CATextlayer. Adapt for Dark Mode without dynamic colors
        // Needs trigger update when `userInterfaceStyle` chagnes
        let userInterfaceStyle = traitCollection.userInterfaceStyle
        buttonBar.buttons.customize { button in
            switch userInterfaceStyle {
            case .dark:
                // Asset.Colors.Label.primary.color
                button.selectedTintColor = UIColor(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 1.0)
                // Asset.Colors.Label.secondary.color
                button.tintColor = UIColor(red: 151.0/255.0, green: 157.0/255.0, blue: 173.0/255.0, alpha: 1.0)
            default:
                // Asset.Colors.Label.primary.color
                button.selectedTintColor = UIColor(red: 40.0/255.0, green: 44.0/255.0, blue: 55.0/255.0, alpha: 1.0)
                // Asset.Colors.Label.secondary.color
                button.tintColor = UIColor(red: 60.0/255.0, green: 60.0/255.0, blue: 67.0/255.0, alpha: 0.6)
            }
            
            button.backgroundColor = .clear
            button.contentInset = UIEdgeInsets(top: 12, left: 26, bottom: 12, right: 26)
        }
    }
    
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
        customizeButtonBarAppearance()
    
        viewModel.$viewControllers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.reloadData()
            }
            .store(in: &disposeBag)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        customizeButtonBarAppearance()
    }

}

extension DiscoveryViewController {
    
    private func setupAppearance(theme: Theme) {
        view.backgroundColor = theme.secondarySystemBackgroundColor
        buttonBarBackgroundView.backgroundColor = theme.systemBackgroundColor
    }
    
}

// MARK: - ScrollViewContainer
extension DiscoveryViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        return (currentViewController as? ScrollViewContainer)?.scrollView ?? UIScrollView()
    }
    func scrollToTop(animated: Bool) {
        if scrollView.contentOffset.y <= 0 {
            scrollToPage(.first, animated: animated)
        } else {
            scrollView.scrollToTop(animated: animated)
        }
    }
}

extension DiscoveryViewController {

    public override var keyCommands: [UIKeyCommand]? {
        return pageboyNavigateKeyCommands
    }

}

// MARK: - PageboyNavigateable
extension DiscoveryViewController: PageboyNavigateable {
    
    var navigateablePageViewController: PageboyViewController {
        return self
    }
    
    @objc func pageboyNavigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        pageboyNavigateKeyCommandHandler(sender)
    }
    
}
