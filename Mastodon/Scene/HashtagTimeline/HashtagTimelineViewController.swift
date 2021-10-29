//
//  HashtagTimelineViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import os.log
import UIKit
import AVKit
import Combine
import GameplayKit
import CoreData

class HashtagTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    
    var viewModel: HashtagTimelineViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    let composeBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        // barButtonItem.tintColor = Asset.Colors.brandBlue.color
        barButtonItem.image = UIImage(systemName: "square.and.pencil")?.withRenderingMode(.alwaysTemplate)
        return barButtonItem
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        return tableView
    }()
    
    let refreshControl = UIRefreshControl()
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension HashtagTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "#\(viewModel.hashtag)"
        titleView.update(title: viewModel.hashtag, subtitle: nil)
        navigationItem.titleView = titleView

        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)
        
        navigationItem.rightBarButtonItem = composeBarButtonItem
        
        composeBarButtonItem.target = self
        composeBarButtonItem.action = #selector(HashtagTimelineViewController.composeBarButtonItemPressed(_:))
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(HashtagTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        viewModel.tableView = tableView
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            statusTableViewCellDelegate: self,
            timelineMiddleLoaderTableViewCellDelegate: self
        )

        // bind refresh control
        viewModel.isFetchingLatestTimeline
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
        
        viewModel.hashtagEntity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tag in
                self?.updatePromptTitle()
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        aspectViewWillAppear(animated)
        
        viewModel.fetchTag()
        if viewModel.loadLatestStateMachine.currentState is HashtagTimelineViewModel.LoadLatestState.Initial {
            viewModel.loadLatestStateMachine.enter(HashtagTimelineViewModel.LoadLatestState.Loading.self)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        aspectViewDidDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            // fix AutoLayout cell height not update after rotate issue
            self.viewModel.cellFrameCache.removeAllObjects()
            self.tableView.reloadData()
        }
    }
    
    private func updatePromptTitle() {
        var subtitle: String?
        defer {
            titleView.update(title: "#" + viewModel.hashtag, subtitle: subtitle)
        }
        guard let histories = viewModel.hashtagEntity.value?.history else {
            return
        }
        if histories.isEmpty {
            // No tag history, remove the prompt title
            return
        } else {
            let sortedHistory = histories.sorted { (h1, h2) -> Bool in
                return h1.day > h2.day
            }
            let peopleTalkingNumber = sortedHistory
                .prefix(2)
                .compactMap({ Int($0.accounts) })
                .reduce(0, +)
            subtitle = L10n.Plural.peopleTalking(peopleTalkingNumber)
        }
    }

}

extension HashtagTimelineViewController {
    
    @objc private func composeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let composeViewModel = ComposeViewModel(context: context, composeKind: .hashtag(hashtag: viewModel.hashtag))
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(HashtagTimelineViewModel.LoadLatestState.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
}

// MARK: - StatusTableViewControllerAspect
extension HashtagTimelineViewController: StatusTableViewControllerAspect { }

// MARK: - TableViewCellHeightCacheableContainer
extension HashtagTimelineViewController: TableViewCellHeightCacheableContainer {
    var cellFrameCache: NSCache<NSNumber, NSValue> {
        return viewModel.cellFrameCache
    }
}

// MARK: - UIScrollViewDelegate
extension HashtagTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        aspectScrollViewDidScroll(scrollView)
    }
}

extension HashtagTimelineViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = HashtagTimelineViewModel.LoadOldestState.Loading
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.loadOldestStateMachine }
}

// MARK: - UITableViewDelegate
extension HashtagTimelineViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return aspectTableView(tableView, estimatedHeightForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        aspectTableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return aspectTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
    }
    
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        aspectTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
    }
    
}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate
extension HashtagTimelineViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}


// MARK: - UITableViewDataSourcePrefetching
extension HashtagTimelineViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        aspectTableView(tableView, prefetchRowsAt: indexPaths)
    }
}

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension HashtagTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func configure(cell: TimelineMiddleLoaderTableViewCell, upperTimelineStatusID: String?, timelineIndexobjectID: NSManagedObjectID?) {
        guard let upperTimelineIndexObjectID = timelineIndexobjectID else {
            return
        }
        viewModel.loadMiddleSateMachineList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let _ = self else { return }
                if let stateMachine = ids[upperTimelineIndexObjectID] {
                    guard let state = stateMachine.currentState else {
                        assertionFailure()
                        return
                    }

                    // make success state same as loading due to snapshot updating delay
                    let isLoading = state is HashtagTimelineViewModel.LoadMiddleState.Loading || state is HashtagTimelineViewModel.LoadMiddleState.Success
                    if isLoading {
                        cell.startAnimating()
                    } else {
                        cell.stopAnimating()
                    }
                } else {
                    cell.stopAnimating()
                }
            }
            .store(in: &cell.disposeBag)
        
        var dict = viewModel.loadMiddleSateMachineList.value
        if let _ = dict[upperTimelineIndexObjectID] {
            // do nothing
        } else {
            let stateMachine = GKStateMachine(states: [
                HashtagTimelineViewModel.LoadMiddleState.Initial(viewModel: viewModel, upperStatusObjectID: upperTimelineIndexObjectID),
                HashtagTimelineViewModel.LoadMiddleState.Loading(viewModel: viewModel, upperStatusObjectID: upperTimelineIndexObjectID),
                HashtagTimelineViewModel.LoadMiddleState.Fail(viewModel: viewModel, upperStatusObjectID: upperTimelineIndexObjectID),
                HashtagTimelineViewModel.LoadMiddleState.Success(viewModel: viewModel, upperStatusObjectID: upperTimelineIndexObjectID),
            ])
            stateMachine.enter(HashtagTimelineViewModel.LoadMiddleState.Initial.self)
            dict[upperTimelineIndexObjectID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict
        }
    }
    
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .homeMiddleLoader(let upper):
            guard let stateMachine = viewModel.loadMiddleSateMachineList.value[upper] else {
                assertionFailure()
                return
            }
            stateMachine.enter(HashtagTimelineViewModel.LoadMiddleState.Loading.self)
        default:
            assertionFailure()
        }
    }
}

// MARK: - AVPlayerViewControllerDelegate
extension HashtagTimelineViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        aspectPlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        aspectPlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
}

// MARK: - StatusTableViewCellDelegate
extension HashtagTimelineViewController: StatusTableViewCellDelegate {
    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
    func parent() -> UIViewController { return self }
}

extension HashtagTimelineViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}

// MARK: - StatusTableViewControllerNavigateable
extension HashtagTimelineViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }
    
    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}
