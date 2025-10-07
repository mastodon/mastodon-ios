//
//  ContentSplitViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-28.
//

import UIKit
import Combine
import CoreDataStack
import MastodonCore

protocol ContentSplitViewControllerDelegate: AnyObject {
    func contentSplitViewController(_ contentSplitViewController: ContentSplitViewController, sidebarViewController: SidebarViewController, didSelectTab tab: Tab)
    func contentSplitViewController(_ contentSplitViewController: ContentSplitViewController, sidebarViewController: SidebarViewController, didDoubleTapTab tab: Tab)
}

final class ContentSplitViewController: UIViewController {

    var disposeBag = Set<AnyCancellable>()
    
    static let sidebarWidth: CGFloat = 89
    
    var authenticationBox: MastodonAuthenticationBox?
    
    weak var delegate: ContentSplitViewControllerDelegate?
    
    private let statusBarBlurView = UIVisualEffectView(effect: nil)
    
    private(set) lazy var sidebarViewController: SidebarViewController = {
        let sidebarViewController = SidebarViewController()
        sidebarViewController.viewModel = SidebarViewModel(authenticationBox: authenticationBox)
        sidebarViewController.delegate = self
        return sidebarViewController
    }()
    
    @Published var currentSupplementaryTab: Tab = .home
    private(set) lazy var mainTabBarController: MainTabBarController = {
        let mainTabBarController = MainTabBarController(authenticationBox: self.authenticationBox)
        return mainTabBarController
    }()

    
}

extension ContentSplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        addChild(sidebarViewController)
        sidebarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sidebarViewController.view)
        sidebarViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            sidebarViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            sidebarViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebarViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebarViewController.view.widthAnchor.constraint(equalToConstant: ContentSplitViewController.sidebarWidth),
        ])
        
        addChild(mainTabBarController)
        mainTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainTabBarController.view)
        sidebarViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            mainTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mainTabBarController.view.leadingAnchor.constraint(equalTo: sidebarViewController.view.trailingAnchor, constant: UIView.separatorLineHeight(of: view)),
            mainTabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // blur behind status bar
        statusBarBlurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusBarBlurView)
        NSLayoutConstraint.activate([
            statusBarBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBlurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        // adapt blur to light/darkmode changes
        updateBlurStyle()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateBlurStyle()
        }
        
        // response keyboard command tab switch
        mainTabBarController.$currentTab
            .sink { [weak self] tab in
                guard let self = self else { return }
                if tab != self.currentSupplementaryTab {
                    self.currentSupplementaryTab = tab
                }
            }
            .store(in: &disposeBag)
        
        $currentSupplementaryTab
            .removeDuplicates()
            .sink(receiveValue: { [weak self] tab in
                guard let self = self else { return }
                self.mainTabBarController.selectedIndex = tab.rawValue
                self.mainTabBarController.currentTab = tab
                self.sidebarViewController.viewModel.currentTab = tab
            })
            .store(in: &disposeBag)
    }
    
    private func updateBlurStyle() {
        let blurStyle: UIBlurEffect.Style
        if traitCollection.userInterfaceStyle == .dark {
            blurStyle = .dark
        } else {
            blurStyle = .light
        }
        
        statusBarBlurView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - SidebarViewControllerDelegate
extension ContentSplitViewController: SidebarViewControllerDelegate {
    
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectTab tab: Tab) {
        delegate?.contentSplitViewController(self, sidebarViewController: sidebarViewController, didSelectTab: tab)
    }
    
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didLongPressItem item: SidebarViewModel.Item, sourceView: UIView) {
        guard case let .tab(tab) = item, tab == .me else { return }
        guard let authenticationBox else { return }
        
        let accountListViewModel = AccountListViewModel(authenticationBox: authenticationBox)
        let accountListViewController = self.sceneCoordinator?.present(
            scene: .accountList(viewModel: accountListViewModel),
            from: nil,
            transition: .popover(sourceView: sourceView)
        ) as! AccountListViewController
        accountListViewController.dragIndicatorView.barView.isHidden = true
        // content width needs > 300 to make checkmark display
        accountListViewController.preferredContentSize = CGSize(width: 375, height: 400)
    }
    
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didDoubleTapItem item: SidebarViewModel.Item, sourceView: UIView) {
        guard case let .tab(tab) = item else { return }
        delegate?.contentSplitViewController(self, sidebarViewController: sidebarViewController, didDoubleTapTab: tab)
    }
}
