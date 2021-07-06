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
import ActiveLabel
import Meta
import MetaTextView

final class NotificationViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    private(set) lazy var viewModel = NotificationViewModel(context: context)

    let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [L10n.Scene.Notification.Title.everything, L10n.Scene.Notification.Title.mentions])
        control.selectedSegmentIndex = NotificationViewModel.NotificationSegment.EveryThing.rawValue
        return control
    }()

    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(NotificationStatusTableViewCell.self, forCellReuseIdentifier: String(describing: NotificationStatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        return tableView
    }()

    let refreshControl = UIRefreshControl()
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
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.titleView = segmentControl
        NSLayoutConstraint.activate([
            segmentControl.widthAnchor.constraint(equalToConstant: 287)
        ])
        segmentControl.addTarget(self, action: #selector(NotificationViewController.segmentedControlValueChanged(_:)), for: .valueChanged)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
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

        viewModel.dataSourceDidUpdated
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                guard self.viewModel.needsScrollToTopAfterDataSourceUpdate else { return }
                self.viewModel.needsScrollToTopAfterDataSourceUpdate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                    self.scrollToTop(animated: true)
                }
            }
            .store(in: &disposeBag)
        
        viewModel.selectedIndex
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] segment in
                guard let self = self else { return }
                self.segmentControl.selectedSegmentIndex = segment.rawValue

                // trigger scroll-to-top after data reload
                self.viewModel.needsScrollToTopAfterDataSourceUpdate = true
                
                guard let domain = self.viewModel.activeMastodonAuthenticationBox.value?.domain, let userID = self.viewModel.activeMastodonAuthenticationBox.value?.userID else {
                    return
                }

                self.viewModel.needsScrollToTopAfterDataSourceUpdate = true

                switch segment {
                case .EveryThing:
                    self.viewModel.notificationPredicate.value = MastodonNotification.predicate(domain: domain, userID: userID)
                case .Mentions:
                    self.viewModel.notificationPredicate.value = MastodonNotification.predicate(domain: domain, userID: userID, typeRaw: Mastodon.Entity.Notification.NotificationType.mention.rawValue)
                }
            }
            .store(in: &disposeBag)

        segmentControl.observe(\.selectedSegmentIndex, options: [.new]) { [weak self] segmentControl, _ in
            guard let self = self else { return }
            // scroll to top when select same segment
            if segmentControl.selectedSegmentIndex == self.viewModel.selectedIndex.value.rawValue {
                self.scrollToTop(animated: true)
            }
        }
        .store(in: &observations)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
        
        // fetch latest notification when will appear
        viewModel.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self)

        
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

        viewModel.selectedIndex.value = NotificationViewModel.NotificationSegment(rawValue: sender.selectedSegmentIndex)!
    }

    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
}

// MARK: - StatusTableViewControllerAspect
extension NotificationViewController: StatusTableViewControllerAspect { }

// MARK: - TableViewCellHeightCacheableContainer
extension NotificationViewController: TableViewCellHeightCacheableContainer {
    var cellFrameCache: NSCache<NSNumber, NSValue> {
        viewModel.cellFrameCache
    }

    func cacheTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        let key = item.hashValue
        let frame = cell.frame
        viewModel.cellFrameCache.setObject(NSValue(cgRect: frame), forKey: NSNumber(value: key))
    }

    func handleTableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource else { return UITableView.automaticDimension }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return UITableView.automaticDimension }
        guard let frame = viewModel.cellFrameCache.object(forKey: NSNumber(value: item.hashValue))?.cgRectValue else {
            if case .bottomLoader = item {
                return TimelineLoaderTableViewCell.cellHeight
            } else {
                return UITableView.automaticDimension
            }
        }

        return ceil(frame.height)
    }
}

// MARK: - UITableViewDelegate

extension NotificationViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        open(item: item)
    }

}

extension NotificationViewController {
    private func open(item: NotificationItem) {
        switch item {
        case .notification(let objectID, _):
            let notification = context.managedObjectContext.object(with: objectID) as! MastodonNotification
            if let status = notification.status {
                let viewModel = ThreadViewModel(context: context, optionalStatus: status)
                coordinator.present(scene: .thread(viewModel: viewModel), from: self, transition: .show)
            } else {
                let viewModel = ProfileViewModel(context: context, optionalMastodonUser: notification.account)
                coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
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

// MARK: - NotificationTableViewCellDelegate
extension NotificationViewController: NotificationTableViewCellDelegate {

    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .notification(let objectID, _):
            guard let notification = try? viewModel.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? MastodonNotification else { return }
            let viewModel = ProfileViewModel(context: context, optionalMastodonUser: notification.account)
            coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
        default:
            break
        }
    }

    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, authorNameLabelDidPressed label: ActiveLabel) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .notification(let objectID, _):
            guard let notification = try? viewModel.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? MastodonNotification else { return }
            let viewModel = ProfileViewModel(context: context, optionalMastodonUser: notification.account)
            coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
        default:
            break
        }
    }


    func notificationTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, acceptButtonDidPressed button: UIButton) {
        viewModel.acceptFollowRequest(notification: notification)
    }
    
    func notificationTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, rejectButtonDidPressed button: UIButton) {
        viewModel.rejectFollowRequest(notification: notification)
    }

    func userNameLabelDidPressed(notification: MastodonNotification) {
        let viewModel = CachedProfileViewModel(context: context, mastodonUser: notification.account)
        DispatchQueue.main.async {
            self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
        }
    }

    func parent() -> UIViewController {
        self
    }
    
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }
    
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }
    
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }

    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
        StatusProviderFacade.responseToStatusMetaTextAction(provider: self, cell: cell, metaText: metaText, didSelectMeta: meta)
    }
}

// MARK: - UIScrollViewDelegate

extension NotificationViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// MARK: - ScrollViewContainer
extension NotificationViewController: ScrollViewContainer {

    var scrollView: UIScrollView { tableView }

    func scrollToTop(animated: Bool) {
        let indexPath = IndexPath(row: 0, section: 0)
        guard viewModel.diffableDataSource?.itemIdentifier(for: indexPath) != nil else { return }
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}

extension NotificationViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = NotificationViewModel.LoadOldestState.Loading
    var loadMoreConfigurableTableView: UITableView { tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { viewModel.loadoldestStateMachine }
}

extension NotificationViewController {
    
    enum CategorySwitch: String, CaseIterable {
        case showEverything
        case showMentions
        
        var title: String {
            switch self {
            case .showEverything:       return L10n.Scene.Notification.Keyobard.showEverything
            case .showMentions:         return L10n.Scene.Notification.Keyobard.showMentions
            }
        }
        
        // UIKeyCommand input
        var input: String {
            switch self {
            case .showEverything:       return "["  // + shift + command
            case .showMentions:         return "]"  // + shift + command
            }
        }
        
        var modifierFlags: UIKeyModifierFlags {
            switch self {
            case .showEverything:       return [.shift, .command]
            case .showMentions:         return [.shift, .command]
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
              let category = CategorySwitch(rawValue: rawValue) else { return }
        
        switch category {
        case .showEverything:
            viewModel.selectedIndex.value = .EveryThing
        case .showMentions:
            viewModel.selectedIndex.value = .Mentions
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return categorySwitchKeyCommands + navigationKeyCommands
    }
}

extension NotificationViewController: TableViewControllerNavigateable {
    
    func navigate(direction: TableViewNavigationDirection) {
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            // navigate up/down on the current selected item
            navigateToStatus(direction: direction, indexPath: indexPathForSelectedRow)
        } else {
            // set first visible item selected
            navigateToFirstVisibleStatus()
        }
    }
    
    private func navigateToStatus(direction: TableViewNavigationDirection, indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let items = diffableDataSource.snapshot().itemIdentifiers
        guard let selectedItem = diffableDataSource.itemIdentifier(for: indexPath),
              let selectedItemIndex = items.firstIndex(of: selectedItem) else {
            return
        }

        let _navigateToItem: NotificationItem? = {
            var index = selectedItemIndex
            while 0..<items.count ~= index {
                index = {
                    switch direction {
                    case .up:   return index - 1
                    case .down: return index + 1
                    }
                }()
                guard 0..<items.count ~= index else { return nil }
                let item = items[index]
                
                guard Self.validNavigateableItem(item) else { continue }
                return item
            }
            return nil
        }()
        
        guard let item = _navigateToItem, let indexPath = diffableDataSource.indexPath(for: item) else { return }
        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
    }
    
    private func navigateToFirstVisibleStatus() {
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return }
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        
        var visibleItems: [NotificationItem] = indexPathsForVisibleRows.sorted().compactMap { indexPath in
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
            guard Self.validNavigateableItem(item) else { return nil }
            return item
        }
        if indexPathsForVisibleRows.first?.row != 0, visibleItems.count > 1 {
            // drop first when visible not the first cell of table
            visibleItems.removeFirst()
        }
        guard let item = visibleItems.first, let indexPath = diffableDataSource.indexPath(for: item) else { return }
        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
    }
    
    static func validNavigateableItem(_ item: NotificationItem) -> Bool {
        switch item {
        case .notification:
            return true
        default:
            return false
        }
    }
    
    func open() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPathForSelectedRow) else { return }
        open(item: item)
    }
    
    func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }

}
