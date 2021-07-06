//
//  ThreadViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import UIKit
import Combine
import CoreData
import AVKit

final class ThreadViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ThreadViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()
    
    let replyBarButtonItem = AdaptiveUserInterfaceStyleBarButtonItem(
        lightImage: UIImage(systemName: "arrowshape.turn.up.left")!,
        darkImage: UIImage(systemName: "arrowshape.turn.up.left.fill")!
    )
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(ThreadReplyLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: ThreadReplyLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ThreadViewController {
    
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
        navigationItem.title = L10n.Scene.Thread.backTitle
        navigationItem.titleView = titleView
        navigationItem.rightBarButtonItem = replyBarButtonItem
        replyBarButtonItem.button.addTarget(self, action: #selector(ThreadViewController.replyBarButtonItemPressed(_:)), for: .touchUpInside)
        
        viewModel.tableView = tableView
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            statusTableViewCellDelegate: self,
            threadReplyLoaderTableViewCellDelegate: self
        )
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.navigationBarTitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tuple in
                guard let self = self else { return }
                guard let (title, emojiDict) = tuple else {
                    self.titleView.update(title: L10n.Scene.Thread.backTitle, subtitle: nil, emojiDict: [:])
                    return
                }
                self.titleView.update(title: title, subtitle: nil, emojiDict: emojiDict)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        aspectViewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        aspectViewDidDisappear(animated)
    }
    
}

extension ThreadViewController {
    @objc private func replyBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let rootItem = viewModel.rootItem.value,
              case let .root(statusObjectID, _) = rootItem else { return }
        let composeViewModel = ComposeViewModel(context: context, composeKind: .reply(repliedToStatusObjectID: statusObjectID))
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
}

// MARK: - StatusTableViewControllerAspect
extension ThreadViewController: StatusTableViewControllerAspect { }

// MARK: - TableViewCellHeightCacheableContainer
extension ThreadViewController: TableViewCellHeightCacheableContainer {
    var cellFrameCache: NSCache<NSNumber, NSValue> { viewModel.cellFrameCache }
}

// MARK: - UITableViewDelegate
extension ThreadViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        aspectTableView(tableView, estimatedHeightForRowAt: indexPath)
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
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        
        // disable root selection
        switch item {
        case .root:
            return nil
        default:
            return indexPath
        }
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

// MARK: - UITableViewDataSourcePrefetching
extension ThreadViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        aspectTableView(tableView, prefetchRowsAt: indexPaths)
    }
}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate
extension ThreadViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}

// MARK: - AVPlayerViewControllerDelegate
extension ThreadViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        aspectPlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        aspectPlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
}

// MARK: - statusTableViewCellDelegate
extension ThreadViewController: StatusTableViewCellDelegate {
    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
    func parent() -> UIViewController { return self }
}

// MARK: - ThreadReplyLoaderTableViewCellDelegate
extension ThreadViewController: ThreadReplyLoaderTableViewCellDelegate {
    func threadReplyLoaderTableViewCell(_ cell: ThreadReplyLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .leafBottomLoader(statusObjectID) = item else { return }
        
        let nodes = viewModel.descendantNodes.value
        nodes.forEach { node in
            expandReply(node: node, statusObjectID: statusObjectID)
        }
        viewModel.descendantNodes.value = nodes
    }
    
    private func expandReply(node: ThreadViewModel.LeafNode, statusObjectID: NSManagedObjectID) {
        if node.objectID == statusObjectID {
            node.isChildrenExpanded = true
        } else {
            for child in node.children {
                expandReply(node: child, statusObjectID: statusObjectID)
            }
        }
    }
}

extension ThreadViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}

// MARK: - StatusTableViewControllerNavigateable
extension ThreadViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }
    
    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}
