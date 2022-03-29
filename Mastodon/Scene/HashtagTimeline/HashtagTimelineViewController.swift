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
import MastodonAsset
import MastodonLocalization

final class HashtagTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "HashtagTimelineViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    var disposeBag = Set<AnyCancellable>()
    var viewModel: HashtagTimelineViewModel!
        
    let composeBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "square.and.pencil")?.withRenderingMode(.alwaysTemplate)
        return barButtonItem
    }()
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()
    
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
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension HashtagTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _title = "#\(viewModel.hashtag)"
        title = _title
        titleView.update(title: _title, subtitle: nil)
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
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.delegate = self
//        tableView.prefetchDataSource = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self
        )
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.loadOldestStateMachine.enter(HashtagTimelineViewModel.LoadOldestState.Loading.self)
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
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

extension HashtagTimelineViewController {
    
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
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        let composeViewModel = ComposeViewModel(
            context: context,
            composeKind: .hashtag(hashtag: viewModel.hashtag),
            authenticationBox: authenticationBox
        )
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }

}

// MARK: - TableViewCellHeightCacheableContainer
//extension HashtagTimelineViewController: TableViewCellHeightCacheableContainer {
//    var cellFrameCache: NSCache<NSNumber, NSValue> {
//        return viewModel.cellFrameCache
//    }
//}

//// MARK: - UIScrollViewDelegate
//extension HashtagTimelineViewController {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        aspectScrollViewDidScroll(scrollView)
//    }
//}

//extension HashtagTimelineViewController: LoadMoreConfigurableTableViewContainer {
//    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
//    typealias LoadingState = HashtagTimelineViewModel.LoadOldestState.Loading
//    var loadMoreConfigurableTableView: UITableView { return tableView }
//    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.loadOldestStateMachine }
//}

// MARK: - UITableViewDelegate
extension HashtagTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:HashtagTimelineViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
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
    // sourcery:end
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return aspectTableView(tableView, estimatedHeightForRowAt: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        aspectTableView(tableView, willDisplay: cell, forRowAt: indexPath)
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

// MARK: - UITableViewDataSourcePrefetching
//extension HashtagTimelineViewController: UITableViewDataSourcePrefetching {
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        aspectTableView(tableView, prefetchRowsAt: indexPaths)
//    }
//}

// MARK: - StatusTableViewCellDelegate
extension HashtagTimelineViewController: StatusTableViewCellDelegate { }

// MARK: - AVPlayerViewControllerDelegate
//extension HashtagTimelineViewController: AVPlayerViewControllerDelegate {
//
//    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        aspectPlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
//    }
//
//    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        aspectPlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
//    }
//
//}

// MARK: - StatusTableViewCellDelegate
//extension HashtagTimelineViewController: StatusTableViewCellDelegate {
//    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
//    func parent() -> UIViewController { return self }
//}

//extension HashtagTimelineViewController {
//    override var keyCommands: [UIKeyCommand]? {
//        return navigationKeyCommands + statusNavigationKeyCommands
//    }
//}
//
//// MARK: - StatusTableViewControllerNavigateable
//extension HashtagTimelineViewController: StatusTableViewControllerNavigateable {
//    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        navigateKeyCommandHandler(sender)
//    }
//    
//    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        statusKeyCommandHandler(sender)
//    }
//}
