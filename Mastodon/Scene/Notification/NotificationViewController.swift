//
//  NotificationViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/12.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import Tabman
import Pageboy
import MastodonCore

final class NotificationViewController: TabmanViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "NotificationViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    var viewModel: NotificationViewModel!
    
    let pageSegmentedControl = UISegmentedControl()

    override func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: TabmanViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        super.pageboyViewController(
            pageboyViewController,
            didScrollToPageAt: index,
            direction: direction,
            animated: animated
        )
        
        viewModel.currentPageIndex = index
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension NotificationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)
        
        setupSegmentedControl(scopes: viewModel.scopes)
        pageSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.titleView = pageSegmentedControl
        NSLayoutConstraint.activate([
            pageSegmentedControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 287)
        ])
        pageSegmentedControl.addTarget(self, action: #selector(NotificationViewController.pageSegmentedControlValueChanged(_:)), for: .valueChanged)

        dataSource = viewModel
        viewModel.$viewControllers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewControllers in
                guard let self = self else { return }
                self.reloadData()
                self.bounces = viewControllers.count > 1
                
            }
            .store(in: &disposeBag)
        
        viewModel.viewControllers = viewModel.scopes.map { scope in
            createViewController(for: scope)
        }
        
        viewModel.$currentPageIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentPageIndex in
                guard let self = self else { return }
                if self.pageSegmentedControl.selectedSegmentIndex != currentPageIndex {
                    self.pageSegmentedControl.selectedSegmentIndex = currentPageIndex
                }
            }
            .store(in: &disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        aspectViewWillAppear(animated)
        
        // fetch latest notification when scroll position is within half screen height to prevent list reload
//        if tableView.contentOffset.y < view.frame.height * 0.5 {
//            viewModel.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self)
//        }

        
        // needs trigger manually after onboarding dismiss
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // reset notification count
        context.notificationService.clearNotificationCountForActiveUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // reset notification count
        context.notificationService.clearNotificationCountForActiveUser()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        aspectViewDidDisappear(animated)
    }
}

extension NotificationViewController {
    private func setupSegmentedControl(scopes: [NotificationTimelineViewModel.Scope]) {
        pageSegmentedControl.removeAllSegments()
        for (i, scope) in scopes.enumerated() {
            pageSegmentedControl.insertSegment(withTitle: scope.title, at: i, animated: false)
        }
        
        // set initial selection
        guard !pageSegmentedControl.isSelected else { return }
        if viewModel.currentPageIndex < pageSegmentedControl.numberOfSegments {
            pageSegmentedControl.selectedSegmentIndex = viewModel.currentPageIndex
        } else {
            pageSegmentedControl.selectedSegmentIndex = 0
        }
    }
    
    private func createViewController(for scope: NotificationTimelineViewModel.Scope) -> UIViewController {
        let viewController = NotificationTimelineViewController()
        viewController.context = context
        viewController.coordinator = coordinator
        viewController.viewModel = NotificationTimelineViewModel(
            context: context,
            authContext: viewModel.authContext,
            scope: scope
        )
        return viewController
    }
}

extension NotificationViewController {
    @objc private func pageSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let index = sender.selectedSegmentIndex
        scrollToPage(.at(index: index), animated: true, completion: nil)
    }
}

// MARK: - ScrollViewContainer
extension NotificationViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        guard let viewController = currentViewController as? NotificationTimelineViewController else {
            return UIScrollView()
        }
        return viewController.scrollView
    }
}


extension NotificationViewController {
    
    enum CategorySwitch: String, CaseIterable {
        case everything
        case mentions
        
        var title: String {
            switch self {
            case .everything:       return L10n.Scene.Notification.Keyobard.showEverything
            case .mentions:         return L10n.Scene.Notification.Keyobard.showMentions
            }
        }
        
        // UIKeyCommand input
        var input: String {
            switch self {
            case .everything:       return "["  // + shift + command
            case .mentions:         return "]"  // + shift + command
            }
        }
        
        var modifierFlags: UIKeyModifierFlags {
            switch self {
            case .everything:       return [.shift, .command]
            case .mentions:         return [.shift, .command]
            }
        }
        
        var propertyList: Any {
            return rawValue
        }
    }
    
    var categorySwitchKeyCommands: [UIKeyCommand] {
        CategorySwitch.allCases.map { category in
            UIKeyCommand(
                title: category.title,
                image: nil,
                action: #selector(NotificationViewController.showCategory(_:)),
                input: category.input,
                modifierFlags: category.modifierFlags,
                propertyList: category.propertyList,
                alternates: [],
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            )
        }
    }

    @objc private func showCategory(_ sender: UIKeyCommand) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let rawValue = sender.propertyList as? String,
              let category = CategorySwitch(rawValue: rawValue)
        else { return }
        
        switch category {
        case .everything:
            scrollToPage(.first, animated: true, completion: nil)
        case .mentions:
            scrollToPage(.last, animated: true, completion: nil)
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return categorySwitchKeyCommands
    }
}
