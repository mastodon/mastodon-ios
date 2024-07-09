//
//  NotificationViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/12.
//

import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import Tabman
import Pageboy
import MastodonCore

final class NotificationViewController: TabmanViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    var viewModel: NotificationViewModel?
    
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
        
        viewModel?.currentPageIndex = index
    }
    
}

extension NotificationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .secondarySystemBackground
        
        setupSegmentedControl(scopes: APIService.MastodonNotificationScope.allCases)
        pageSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.titleView = pageSegmentedControl
        NSLayoutConstraint.activate([
            pageSegmentedControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 287)
        ])
        pageSegmentedControl.addTarget(self, action: #selector(NotificationViewController.pageSegmentedControlValueChanged(_:)), for: .valueChanged)

        dataSource = viewModel
        viewModel?.$viewControllers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewControllers in
                guard let self = self else { return }
                self.reloadData()
                self.bounces = viewControllers.count > 1
                
            }
            .store(in: &disposeBag)
        
        viewModel?.viewControllers = APIService.MastodonNotificationScope.allCases.map { scope in
            createViewController(for: scope)
        }
        
        viewModel?.$currentPageIndex
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
        
        // https://github.com/mastodon/documentation/pull/1447#issuecomment-2149225659
        if let viewModel, viewModel.notificationPolicy != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(NotificationViewController.showNotificationPolicySettings(_:)))
        }

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

    //MARK: - Actions

    @objc private func showNotificationPolicySettings(_ sender: Any) {
        guard let viewModel, let policy = viewModel.notificationPolicy else { return }

        let policyViewModel = NotificationFilterViewModel(
            appContext: viewModel.context,
            notFollowing: policy.filterNotFollowing,
            noFollower: policy.filterNotFollowers,
            newAccount: policy.filterNewAccounts,
            privateMentions: policy.filterPrivateMentions
        )
        //TODO: Move to SceneCoordinator, we'd need a new case for this
        let notificationPolicyViewController = NotificationPolicyViewController(viewModel: policyViewModel)
        notificationPolicyViewController.modalPresentationStyle = .formSheet
        let navigationController = UINavigationController(rootViewController: notificationPolicyViewController)

        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

        present(navigationController, animated: true)
    }
}

extension NotificationViewController {
    private func setupSegmentedControl(scopes: [NotificationTimelineViewModel.Scope]) {
        pageSegmentedControl.removeAllSegments()
        for (i, scope) in scopes.enumerated() {
            pageSegmentedControl.insertSegment(withTitle: scope.title, at: i, animated: false)
        }
        
        // set initial selection
        guard let viewModel, !pageSegmentedControl.isSelected else { return }
        if viewModel.currentPageIndex < pageSegmentedControl.numberOfSegments {
            pageSegmentedControl.selectedSegmentIndex = viewModel.currentPageIndex
        } else {
            pageSegmentedControl.selectedSegmentIndex = 0
        }
    }

    private func createViewController(for scope: NotificationTimelineViewModel.Scope) -> UIViewController {
        guard let viewModel else { return UITableViewController() }

        let viewController = NotificationTimelineViewController(
            viewModel: NotificationTimelineViewModel(
                context: context,
                authContext: viewModel.authContext,
                scope: scope, notificationPolicy: viewModel.notificationPolicy
            ),
            context: context,
            coordinator: coordinator
        )

        return viewController
    }
}

extension NotificationViewController {
    @objc private func pageSegmentedControlValueChanged(_ sender: UISegmentedControl) {
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
        guard let rawValue = sender.propertyList as? String,
              let category = CategorySwitch(rawValue: rawValue)
        else { return }
        
        switch category {
        case .mentions:
            scrollToPage(.last, animated: true, completion: nil)
        case .everything:
            scrollToPage(.first, animated: true, completion: nil)
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return categorySwitchKeyCommands
    }
}
