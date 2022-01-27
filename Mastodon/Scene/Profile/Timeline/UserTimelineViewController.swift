//
//  UserTimelineViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreDataStack
import GameplayKit

final class UserTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "UserTimelineViewController", category: "ViewController")
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserTimelineViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TimelineHeaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineHeaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    var overrideNavigationScrollPosition: UITableView.ScrollPosition? = nil

    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)
        
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
                guard self.view.window != nil else { return }
                self.viewModel.stateMachine.enter(UserTimelineViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UIScrollViewDelegate
//extension UserTimelineViewController {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        aspectScrollViewDidScroll(scrollView)
//    }
//}

// MARK: - UITableViewDelegate
extension UserTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:UserTimelineViewController.AutoGenerateTableViewDelegate

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
//        aspectTableView(tableView, estimatedHeightForRowAt: indexPath)
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

//// MARK: - UITableViewDataSourcePrefetching
//extension UserTimelineViewController: UITableViewDataSourcePrefetching {
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        aspectTableView(tableView, prefetchRowsAt: indexPaths)
//    }
//}

// MARK: - AVPlayerViewControllerDelegate
//extension UserTimelineViewController: AVPlayerViewControllerDelegate {
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

// MARK: - TimelinePostTableViewCellDelegate
//extension UserTimelineViewController: StatusTableViewCellDelegate {
//    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
//    func parent() -> UIViewController { return self }
//}

// MARK: - CustomScrollViewContainerController
extension UserTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return tableView }
}

// MARK: - LoadMoreConfigurableTableViewContainer
//extension UserTimelineViewController: LoadMoreConfigurableTableViewContainer {
//    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
//    typealias LoadingState = UserTimelineViewModel.State.Loading
//
//    var loadMoreConfigurableTableView: UITable``````View { return tableView }
//    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
//}

//extension UserTimelineViewController {
//    override var keyCommands: [UIKeyCommand]? {
//        return navigationKeyCommands + statusNavigationKeyCommands
//    }
//}
//
//// MARK: - StatusTableViewControllerNavigateable
//extension UserTimelineViewController: StatusTableViewControllerNavigateable {
//    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        navigateKeyCommandHandler(sender)
//    }
//
//    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        statusKeyCommandHandler(sender)
//    }
//}

// MARK: - StatusTableViewCellDelegate
extension UserTimelineViewController: StatusTableViewCellDelegate { }
