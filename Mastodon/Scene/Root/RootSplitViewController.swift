//
//  RootSplitViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonCore

final class RootSplitViewController: UISplitViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    static let sidebarWidth: CGFloat = 89
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var authContext: AuthContext?
    
    private var isPrimaryDisplay = false
    
    private(set) lazy var contentSplitViewController: ContentSplitViewController = {
        let contentSplitViewController = ContentSplitViewController()
        contentSplitViewController.context = context
        contentSplitViewController.coordinator = coordinator
        contentSplitViewController.authContext = authContext
        contentSplitViewController.delegate = self
        return contentSplitViewController
    }()
    
    private(set) lazy var searchViewController: SearchViewController = {
        let searchViewController = SearchViewController()
        searchViewController.context = context
        searchViewController.coordinator = coordinator
        searchViewController.viewModel = .init(
            context: context,
            authContext: authContext
        )
        return searchViewController
    }()
    
    lazy var compactMainTabBarViewController = MainTabBarController(context: context, coordinator: coordinator, authContext: authContext)
    
    let separatorLine = UIView.separatorLine
    
    init(context: AppContext, coordinator: SceneCoordinator, authContext: AuthContext?) {
        self.context = context
        self.coordinator = coordinator
        self.authContext = authContext
        super.init(style: .doubleColumn)
        
        primaryEdge = .trailing
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .twoBesideSecondary
        preferredSplitBehavior = .tile
        delegate = self
        
        // disable edge swipe gesture
        presentsWithGesture = false
        
        if #available(iOS 14.5, *) {
            displayModeButtonVisibility = .never
        } else {
            // Fallback on earlier versions
        }
        
        setViewController(searchViewController, for: .primary)
        setViewController(contentSplitViewController, for: .secondary)
        setViewController(compactMainTabBarViewController, for: .compact)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension RootSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateBehavior(size: view.frame.size)
        
        setupBackground(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackground(theme: theme)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateBehavior(size: view.frame.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.updateBehavior(size: size)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupBackground(theme: ThemeService.shared.currentTheme.value)
    }
    
    private func updateBehavior(size: CGSize) {
        if size.width > 960 {
            show(.primary)
            isPrimaryDisplay = true
            
        } else {
            hide(.primary)
            isPrimaryDisplay = false
        }
        
        switch (contentSplitViewController.currentSupplementaryTab, isPrimaryDisplay) {
        case (.search, true):
            // needs switch to other tab when primary display
            // use FIFO queue save tab history
            contentSplitViewController.currentSupplementaryTab = .home
        default:
            // do nothing
            break
        }
    }

}

extension RootSplitViewController {

    private func setupBackground(theme: Theme) {
        // this set column separator line color
        view.backgroundColor = theme.separator
    }
    
}

// MARK: - ContentSplitViewControllerDelegate
extension RootSplitViewController: ContentSplitViewControllerDelegate {
    func contentSplitViewController(_ contentSplitViewController: ContentSplitViewController, sidebarViewController: SidebarViewController, didSelectTab tab: MainTabBarController.Tab) {
        guard let _ = MainTabBarController.Tab.allCases.firstIndex(of: tab) else {
            assertionFailure()
            return
        }
        switch tab {
        case .search:
            guard isPrimaryDisplay else {
                // only control search tab behavior when primary display
                fallthrough
            }
            guard let navigationController = searchViewController.navigationController else { return }
            if navigationController.viewControllers.count == 1 {
                searchViewController.searchBarTapPublisher.send("")
            } else {
                navigationController.popToRootViewController(animated: true)
            }
        
        default:
            let previousTab = contentSplitViewController.currentSupplementaryTab
            contentSplitViewController.currentSupplementaryTab = tab
            
            if previousTab == tab,
               let navigationController = contentSplitViewController.mainTabBarController.selectedViewController as? UINavigationController
            {
                navigationController.popToRootViewController(animated: true)
            }
            
        }
    }
}

// MARK: - UISplitViewControllerDelegate
extension RootSplitViewController: UISplitViewControllerDelegate {
    
    private static func transform(from: UITabBarController, to: UITabBarController) {
        let sourceNavigationControllers = from.viewControllers ?? []
        let targetNavigationControllers = to.viewControllers ?? []
        
        for (source, target) in zip(sourceNavigationControllers, targetNavigationControllers) {
            guard let source = source as? UINavigationController,
                  let target = target as? UINavigationController
            else { continue }
            let viewControllers = source.popToRootViewController(animated: false) ?? []
            _ = target.popToRootViewController(animated: false)
            target.viewControllers.append(contentsOf: viewControllers)
        }
        
        to.selectedIndex = from.selectedIndex
    }
    
    private static func transform(from: UINavigationController, to: UINavigationController) {
        let viewControllers = from.popToRootViewController(animated: false) ?? []
        to.viewControllers.append(contentsOf: viewControllers)
    }
    
    // .regular to .compact
    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        switch proposedTopColumn {
        case .compact:
            RootSplitViewController.transform(from: contentSplitViewController.mainTabBarController, to: compactMainTabBarViewController)
            compactMainTabBarViewController.currentTab = contentSplitViewController.currentSupplementaryTab

        default:
            assertionFailure()
        }

        return proposedTopColumn
    }
    
    // .compact to .regular
    func splitViewController(
        _ svc: UISplitViewController,
        displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode
    ) -> UISplitViewController.DisplayMode {
        let compactNavigationController = compactMainTabBarViewController.selectedViewController as? UINavigationController

        if let topMost = compactNavigationController?.topMost,
           topMost is AccountListViewController {
            topMost.dismiss(animated: false, completion: nil)
        }

        RootSplitViewController.transform(from: compactMainTabBarViewController, to: contentSplitViewController.mainTabBarController)
        
        let tab = compactMainTabBarViewController.currentTab
        if tab == .search {
            contentSplitViewController.currentSupplementaryTab = .home
        } else {
            contentSplitViewController.currentSupplementaryTab = compactMainTabBarViewController.currentTab
        }

        return proposedDisplayMode
    }

}

// MARK: - WizardViewControllerDelegate
extension RootSplitViewController: WizardViewControllerDelegate {
    
    func readyToLayoutItem(_ wizardViewController: WizardViewController, item: WizardViewController.Item) -> Bool {
        guard traitCollection.horizontalSizeClass != .compact else {
            return compactMainTabBarViewController.readyToLayoutItem(wizardViewController, item: item)
        }
        
        switch item {
        case .multipleAccountSwitch:
            return contentSplitViewController.sidebarViewController.viewModel.isReadyForWizardAvatarButton
        }
    }
    
    
    func layoutSpotlight(_ wizardViewController: WizardViewController, item: WizardViewController.Item) -> UIBezierPath {
        guard traitCollection.horizontalSizeClass != .compact else {
            return compactMainTabBarViewController.layoutSpotlight(wizardViewController, item: item)
        }
        
        switch item {
        case .multipleAccountSwitch:
            guard let frame = avatarButtonFrameInWizardView(wizardView: wizardViewController.view)
            else {
                assertionFailure()
                return UIBezierPath()
            }
            return UIBezierPath(ovalIn: frame)
        }
    }
    
    func layoutWizardCard(_ wizardViewController: WizardViewController, item: WizardViewController.Item) {
        guard traitCollection.horizontalSizeClass != .compact else {
            return compactMainTabBarViewController.layoutWizardCard(wizardViewController, item: item)
        }
        
        guard let frame = avatarButtonFrameInWizardView(wizardView: wizardViewController.view) else {
            return
        }
        
        let anchorView = UIView()
        anchorView.frame = frame
        wizardViewController.backgroundView.addSubview(anchorView)
        
        let wizardCardView = WizardCardView()
        wizardCardView.arrowRectCorner = .allCorners    // no arrow
        wizardCardView.titleLabel.text = item.title
        wizardCardView.descriptionLabel.text = item.description
        
        wizardCardView.translatesAutoresizingMaskIntoConstraints = false
        wizardViewController.backgroundView.addSubview(wizardCardView)
        NSLayoutConstraint.activate([
            wizardCardView.centerYAnchor.constraint(equalTo: anchorView.centerYAnchor),
            wizardCardView.leadingAnchor.constraint(equalTo: anchorView.trailingAnchor, constant: 20), // 20pt spacing
            wizardCardView.widthAnchor.constraint(equalToConstant: 320),
        ])
        wizardCardView.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func avatarButtonFrameInWizardView(wizardView: UIView) -> CGRect? {
       guard let diffableDataSource = contentSplitViewController.sidebarViewController.viewModel.diffableDataSource,
             let indexPath = diffableDataSource.indexPath(for: .tab(.me)),
             let cell = contentSplitViewController.sidebarViewController.collectionView.cellForItem(at: indexPath) as? SidebarListCollectionViewCell,
             let contentView = cell._contentView,
             let frame = sourceViewFrameInTargetView(
                sourceView: contentView.avatarButton,
                targetView: wizardView
             )
        else {
            assertionFailure()
            return nil
        }
        return frame
    }

    private func sourceViewFrameInTargetView(
        sourceView: UIView,
        targetView: UIView
    ) -> CGRect? {
        guard let superview = sourceView.superview else {
            assertionFailure()
            return nil
        }
        return superview.convert(sourceView.frame, to: targetView)
    }
}
