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

final class NotificationViewController: TabmanViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "NotificationViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    private(set) lazy var viewModel = NotificationViewModel(context: context)
    
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
            
//        segmentControl.translatesAutoresizingMaskIntoConstraints = false
//        navigationItem.titleView = segmentControl
//        NSLayoutConstraint.activate([
//            segmentControl.widthAnchor.constraint(equalToConstant: 287)
//        ])
//        segmentControl.addTarget(self, action: #selector(NotificationViewController.segmentedControlValueChanged(_:)), for: .valueChanged)
//
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(tableView)
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: view.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//
//        tableView.refreshControl = refreshControl
//        refreshControl.addTarget(self, action: #selector(NotificationViewController.refreshControlValueChanged(_:)), for: .valueChanged)
//
//        tableView.delegate = self
//        viewModel.tableView = tableView
//        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
//        viewModel.setupDiffableDataSource(
//            for: tableView,
//            dependency: self,
//            delegate: self,
//            statusTableViewCellDelegate: self
//        )
//        viewModel.viewDidLoad.send()
//        
//        // bind refresh control
//        viewModel.isFetchingLatestNotification
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isFetching in
//                guard let self = self else { return }
//                if !isFetching {
//                    UIView.animate(withDuration: 0.5) { [weak self] in
//                        guard let self = self else { return }
//                        self.refreshControl.endRefreshing()
//                    }
//                }
//            }
//            .store(in: &disposeBag)
//
//        viewModel.dataSourceDidUpdated
//            .receive(on: RunLoop.main)
//            .sink { [weak self] in
//                guard let self = self else { return }
//                guard self.viewModel.needsScrollToTopAfterDataSourceUpdate else { return }
//                self.viewModel.needsScrollToTopAfterDataSourceUpdate = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
//                    self.scrollToTop(animated: true)
//                }
//            }
//            .store(in: &disposeBag)
//        
//        viewModel.selectedIndex
//            .removeDuplicates()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] segment in
//                guard let self = self else { return }
//                self.segmentControl.selectedSegmentIndex = segment.rawValue
//
//                // trigger scroll-to-top after data reload
//                self.viewModel.needsScrollToTopAfterDataSourceUpdate = true
//                
//                guard let domain = self.viewModel.activeMastodonAuthenticationBox.value?.domain, let userID = self.viewModel.activeMastodonAuthenticationBox.value?.userID else {
//                    return
//                }
//
//                self.viewModel.needsScrollToTopAfterDataSourceUpdate = true
//
//                switch segment {
//                case .everyThing:
//                    self.viewModel.notificationPredicate.value = MastodonNotification.predicate(domain: domain, userID: userID)
//                case .mentions:
//                    self.viewModel.notificationPredicate.value = MastodonNotification.predicate(domain: domain, userID: userID, typeRaw: Mastodon.Entity.Notification.NotificationType.mention.rawValue)
//                }
//            }
//            .store(in: &disposeBag)
//
//        segmentControl.observe(\.selectedSegmentIndex, options: [.new]) { [weak self] segmentControl, _ in
//            guard let self = self else { return }
//            // scroll to top when select same segment
//            if segmentControl.selectedSegmentIndex == self.viewModel.selectedIndex.value.rawValue {
//                self.scrollToTop(animated: true)
//            }
//        }
//        .store(in: &observations)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        aspectViewWillAppear(animated)
        
        // fetch latest notification when scroll position is within half screen height to prevent list reload
//        if tableView.contentOffset.y < view.frame.height * 0.5 {
//            viewModel.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self)
//        }

        
        // needs trigger manually after onboarding dismiss
//        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            if (self.viewModel.fetchedResultsController.fetchedObjects ?? []).count == 0 {
////                self.viewModel.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self)
//            }
//        }
//
//        // reset notification count
//        context.notificationService.clearNotificationCountForActiveUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        // reset notification count
//        context.notificationService.clearNotificationCountForActiveUser()
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


//// MARK: - TableViewCellHeightCacheableContainer
//extension NotificationViewController: TableViewCellHeightCacheableContainer {
//    var cellFrameCache: NSCache<NSNumber, NSValue> { return viewModel.cellFrameCache }
//
//    func cacheTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        switch item {
//        case .notification(let objectID, _),
//            .notificationStatus(let objectID, _):
//            guard let object = try? viewModel.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? MastodonNotification else { return }
//            let key = object.objectID.hashValue
//            let frame = cell.frame
//            viewModel.cellFrameCache.setObject(NSValue(cgRect: frame), forKey: NSNumber(value: key))
//        case .bottomLoader:
//            break
//        }
//    }
//
//    func handleTableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return UITableView.automaticDimension }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return UITableView.automaticDimension }
//        switch item {
//        case .notification(let objectID, _),
//             .notificationStatus(let objectID, _):
//            guard let object = try? viewModel.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? MastodonNotification else { return UITableView.automaticDimension }
//            let key = object.objectID.hashValue
//            guard let frame = viewModel.cellFrameCache.object(forKey: NSNumber(value: key))?.cgRectValue else { return UITableView.automaticDimension }
//            return frame.height
//        case .bottomLoader:
//            return TimelineLoaderTableViewCell.cellHeight
//        }
//    }
//}

// MARK: - UITableViewDelegate

extension NotificationViewController: UITableViewDelegate {
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        aspectTableView(tableView, estimatedHeightForRowAt: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        switch item {
//        case .notificationStatus:
//            aspectTableView(tableView, willDisplay: cell, forRowAt: indexPath)
//        case .bottomLoader:
//            if !tableView.isDragging, !tableView.isDecelerating {
//                viewModel.loadOldestStateMachine.enter(NotificationViewModel.LoadOldestState.Loading.self)
//            }
//        default:
//            break
//        }
//    }
//
//    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        aspectTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        aspectTableView(tableView, didSelectRowAt: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        return aspectTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
//    }
//
//    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        return aspectTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        return aspectTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
//        aspectTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
//    }

}

//extension NotificationViewController {
//    private func open(item: NotificationItem) {
//        switch item {
//        case .notification(let objectID, _):
//            let notification = context.managedObjectContext.object(with: objectID) as! MastodonNotification
//            if let status = notification.status {
//                let viewModel = ThreadViewModel(
//                    context: context,
//                    optionalRoot: .root(context: .init(status: status.asRecord))
//                )
//                coordinator.present(scene: .thread(viewModel: viewModel), from: self, transition: .show)
//            } else {
//                let viewModel = ProfileViewModel(
//                    context: context,
//                    optionalMastodonUser: notification.account
//                )
//                coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
//            }
//        default:
//            break
//        }
//    }
//}

// MARK: - NotificationTableViewCellDelegate
//extension NotificationViewController: NotificationTableViewCellDelegate {
//
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        switch item {
//        case .notification(let objectID, _):
//            guard let notification = try? viewModel.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? MastodonNotification else { return }
//            let viewModel = ProfileViewModel(context: context, optionalMastodonUser: notification.account)
//            coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
//        default:
//            break
//        }
//    }
//
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, authorNameLabelDidPressed label: MetaLabel) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        switch item {
//        case .notification(let objectID, _):
//            guard let notification = try? viewModel.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? MastodonNotification else { return }
//            let viewModel = ProfileViewModel(context: context, optionalMastodonUser: notification.account)
//            coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
//        default:
//            break
//        }
//    }
//
//    func notificationTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, acceptButtonDidPressed button: UIButton) {
//        viewModel.acceptFollowRequest(notification: notification)
//    }
//
//    func notificationTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, rejectButtonDidPressed button: UIButton) {
//        viewModel.rejectFollowRequest(notification: notification)
//    }
//
//    func userNameLabelDidPressed(notification: MastodonNotification) {
//        let viewModel = CachedProfileViewModel(context: context, mastodonUser: notification.account)
//        DispatchQueue.main.async {
//            self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
//        }
//    }
//
//    func parent() -> UIViewController {
//        self
//    }
//
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton) {
//        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
//    }
//
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
//        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
//    }
//
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
//        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
//    }
//
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
//        StatusProviderFacade.responseToStatusMetaTextAction(provider: self, cell: cell, metaText: metaText, didSelectMeta: meta)
//    }
//}

// MARK: - UIScrollViewDelegate

//extension NotificationViewController {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        handleScrollViewDidScroll(scrollView)
//    }
//}

// MARK: - ScrollViewContainer
//extension NotificationViewController: ScrollViewContainer {
//
//    var scrollView: UIScrollView { tableView }
//
//    func scrollToTop(animated: Bool) {
//        let indexPath = IndexPath(row: 0, section: 0)
//        guard viewModel.diffableDataSource?.itemIdentifier(for: indexPath) != nil else { return }
//        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
//    }
//}

// MARK: - AVPlayerViewControllerDelegate
//extension NotificationViewController: AVPlayerViewControllerDelegate {
//    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
//    }
//
//    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
//    }
//}

//// MARK: - statusTableViewCellDelegate
//extension NotificationViewController: StatusTableViewCellDelegate {
//    var playerViewControllerDelegate: AVPlayerViewControllerDelegate? {
//        return self
//    }
//}

//extension NotificationViewController {
//
//    enum CategorySwitch: String, CaseIterable {
//        case showEverything
//        case showMentions
//
//        var title: String {
//            switch self {
//            case .showEverything:       return L10n.Scene.Notification.Keyobard.showEverything
//            case .showMentions:         return L10n.Scene.Notification.Keyobard.showMentions
//            }
//        }
//
//        // UIKeyCommand input
//        var input: String {
//            switch self {
//            case .showEverything:       return "["  // + shift + command
//            case .showMentions:         return "]"  // + shift + command
//            }
//        }
//
//        var modifierFlags: UIKeyModifierFlags {
//            switch self {
//            case .showEverything:       return [.shift, .command]
//            case .showMentions:         return [.shift, .command]
//            }
//        }
//
//        var propertyList: Any {
//            return rawValue
//        }
//    }
//
//    var categorySwitchKeyCommands: [UIKeyCommand] {
//        CategorySwitch.allCases.map { category in
//            UIKeyCommand(
//                title: category.title,
//                image: nil,
//                action: #selector(NotificationViewController.showCategory(_:)),
//                input: category.input,
//                modifierFlags: category.modifierFlags,
//                propertyList: category.propertyList,
//                alternates: [],
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            )
//        }
//    }
//
//    @objc private func showCategory(_ sender: UIKeyCommand) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        guard let rawValue = sender.propertyList as? String,
//              let category = CategorySwitch(rawValue: rawValue) else { return }
//
//        switch category {
//        case .showEverything:
//            viewModel.selectedIndex.value = .everyThing
//        case .showMentions:
//            viewModel.selectedIndex.value = .mentions
//        }
//    }
//
//    override var keyCommands: [UIKeyCommand]? {
//        return categorySwitchKeyCommands + navigationKeyCommands
//    }
//}

//extension NotificationViewController: TableViewControllerNavigateable {
//    
//    func navigate(direction: TableViewNavigationDirection) {
//        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
//            // navigate up/down on the current selected item
//            navigateToStatus(direction: direction, indexPath: indexPathForSelectedRow)
//        } else {
//            // set first visible item selected
//            navigateToFirstVisibleStatus()
//        }
//    }
//    
//    private func navigateToStatus(direction: TableViewNavigationDirection, indexPath: IndexPath) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        let items = diffableDataSource.snapshot().itemIdentifiers
//        guard let selectedItem = diffableDataSource.itemIdentifier(for: indexPath),
//              let selectedItemIndex = items.firstIndex(of: selectedItem) else {
//            return
//        }
//
//        let _navigateToItem: NotificationItem? = {
//            var index = selectedItemIndex
//            while 0..<items.count ~= index {
//                index = {
//                    switch direction {
//                    case .up:   return index - 1
//                    case .down: return index + 1
//                    }
//                }()
//                guard 0..<items.count ~= index else { return nil }
//                let item = items[index]
//                
//                guard Self.validNavigateableItem(item) else { continue }
//                return item
//            }
//            return nil
//        }()
//        
//        guard let item = _navigateToItem, let indexPath = diffableDataSource.indexPath(for: item) else { return }
//        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
//        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
//    }
//    
//    private func navigateToFirstVisibleStatus() {
//        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return }
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        
//        var visibleItems: [NotificationItem] = indexPathsForVisibleRows.sorted().compactMap { indexPath in
//            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
//            guard Self.validNavigateableItem(item) else { return nil }
//            return item
//        }
//        if indexPathsForVisibleRows.first?.row != 0, visibleItems.count > 1 {
//            // drop first when visible not the first cell of table
//            visibleItems.removeFirst()
//        }
//        guard let item = visibleItems.first, let indexPath = diffableDataSource.indexPath(for: item) else { return }
//        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
//        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
//    }
//    
//    static func validNavigateableItem(_ item: NotificationItem) -> Bool {
//        switch item {
//        case .notification:
//            return true
//        default:
//            return false
//        }
//    }
//    
//    func open() {
//        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPathForSelectedRow) else { return }
//        open(item: item)
//    }
//    
//    func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        navigateKeyCommandHandler(sender)
//    }
//
//}
