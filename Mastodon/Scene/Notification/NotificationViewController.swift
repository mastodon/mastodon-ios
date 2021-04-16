//
//  NotificationViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/12.
//

import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import OSLog
import UIKit

final class NotificationViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = NotificationViewModel(context: context)
    
    let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [L10n.Scene.Notification.Title.everything, L10n.Scene.Notification.Title.mentions])
        control.selectedSegmentIndex = 0
        return control
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: String(describing: NotificationTableViewCell.self))
        tableView.register(NotificationStatusTableViewCell.self, forCellReuseIdentifier: String(describing: NotificationStatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    let refreshControl = UIRefreshControl()
}

extension NotificationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.Background.pure.color
        navigationItem.titleView = segmentControl
        segmentControl.addTarget(self, action: #selector(NotificationViewController.segmentedControlValueChanged(_:)), for: .valueChanged)
        view.addSubview(tableView)
        tableView.constrain([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(NotificationViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
        tableView.delegate = self
        viewModel.tableView = tableView
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        viewModel.setupDiffableDataSource(for: tableView, delegate: self, dependency: self)
        viewModel.viewDidLoad.send()
        // bind refresh control
        viewModel.isFetchingLatestNotification
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFetching in
                guard let self = self else { return }
                if !isFetching {
                    UIView.animate(withDuration: 0.5) { [weak self] in
                        guard let self = self else { return }
                        self.refreshControl.endRefreshing()
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // needs trigger manually after onboarding dismiss
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (self.viewModel.fetchedResultsController.fetchedObjects ?? []).count == 0 {
                self.viewModel.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            self.tableView.reloadData()
        }
    }
}

extension NotificationViewController {
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        os_log("%{public}s[%{public}ld], %{public}s: select at index: %ld", (#file as NSString).lastPathComponent, #line, #function, sender.selectedSegmentIndex)
        guard let domain = viewModel.activeMastodonAuthenticationBox.value?.domain, let userID = viewModel.activeMastodonAuthenticationBox.value?.userID else {
            return
        }
        if sender.selectedSegmentIndex == 0 {
            viewModel.notificationPredicate.value = MastodonNotification.predicate(domain: domain, userID: userID)
        } else {
            viewModel.notificationPredicate.value = MastodonNotification.predicate(domain: domain,userID: userID, typeRaw: Mastodon.Entity.Notification.NotificationType.mention.rawValue)
        }
        viewModel.selectedIndex.value = NotificationViewModel.NotificationSegment.init(rawValue: sender.selectedSegmentIndex)!
    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
}

// MARK: - UITableViewDelegate

extension NotificationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .notification(let objectID):
            let notification = context.managedObjectContext.object(with: objectID) as! MastodonNotification
            if notification.status != nil {
                // TODO: goto status detail vc
            } else {
                let viewModel = ProfileViewModel(context: context, optionalMastodonUser: notification.account)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
                }
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .bottomLoader:
            if !tableView.isDragging, !tableView.isDecelerating {
                viewModel.loadoldestStateMachine.enter(NotificationViewModel.LoadOldestState.Loading.self)
            }
        default:
            break
        }
    }
}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate

extension NotificationViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar? {
        navigationController?.navigationBar
    }
}

extension NotificationViewController: NotificationTableViewCellDelegate {
    func userAvatarDidPressed(notification: MastodonNotification) {
        let viewModel = ProfileViewModel(context: context, optionalMastodonUser: notification.account)
        DispatchQueue.main.async {
            self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
        }
    }
    
    func parent() -> UIViewController {
        self
    }
}

// MARK: - UIScrollViewDelegate

extension NotificationViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

extension NotificationViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = NotificationViewModel.LoadOldestState.Loading
    var loadMoreConfigurableTableView: UITableView { tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { viewModel.loadoldestStateMachine }
}
