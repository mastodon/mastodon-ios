//
//  SearchResultViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import os.log
import UIKit
import Combine
import MastodonCore
import MastodonUI

final class SearchResultViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "SearchResultViewController", category: "ViewController")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    var viewModel: SearchResultViewModel!
    var disposeBag = Set<AnyCancellable>()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        return tableView
    }()

}

extension SearchResultViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

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
                self.viewModel.stateMachine.enter(SearchResultViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)

        // listen keyboard events and set content inset
        let keyboardEventPublishers = Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow,
            KeyboardResponderService.shared.state,
            KeyboardResponderService.shared.endFrame
        )
        Publishers.CombineLatest3(
            keyboardEventPublishers,
            viewModel.viewDidAppear,
            viewModel.didDataSourceUpdate
        )
        .sink(receiveValue: { [weak self] keyboardEvents, _, _ in
            guard let self = self else { return }
            let (isShow, state, endFrame) = keyboardEvents

            // update keyboard background color
            guard isShow, state == .dock else {
                self.tableView.contentInset.bottom = 0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0
                return
            }
            // isShow AND dock state

            // adjust inset for tableView
            let contentFrame = self.view.convert(self.tableView.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                self.tableView.contentInset.bottom = self.view.safeAreaInsets.bottom
                self.tableView.verticalScrollIndicatorInsets.bottom = self.view.safeAreaInsets.bottom
                return
            }

            self.tableView.contentInset.bottom = padding - self.view.safeAreaInsets.bottom
            self.tableView.verticalScrollIndicatorInsets.bottom = padding - self.view.safeAreaInsets.bottom
        })
        .store(in: &disposeBag)
//
        // works for already onscreen page
        viewModel.navigationBarFrame
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                guard let self = self else { return }
                guard self.viewModel.viewDidAppear.value else { return }
                self.tableView.contentInset.top = frame.height
                self.tableView.verticalScrollIndicatorInsets.top = frame.height
            }
            .store(in: &disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // works for appearing page
        if !viewModel.viewDidAppear.value {
            tableView.contentInset.top = viewModel.navigationBarFrame.value.height
            tableView.contentOffset.y = -viewModel.navigationBarFrame.value.height
        }

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear.value = true
    }

}

extension SearchResultViewController {
    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemGroupedBackgroundColor
//        tableView.backgroundColor = theme.systemBackgroundColor
//        searchHeader.backgroundColor = theme.systemGroupedBackgroundColor
    }

}

// MARK: - StatusTableViewCellDelegate
extension SearchResultViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension SearchResultViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:SearchResultViewController.AutoGenerateTableViewDelegate

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
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//
//        viewModel.persistSearchHistory(for: item)
//
//        switch item {
//        case .account(let account):
//            let profileViewModel = RemoteProfileViewModel(context: context, userID: account.id)
//            coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
//        case .hashtag(let hashtag):
//            let hashtagViewModel = HashtagTimelineViewModel(context: context, hashtag: hashtag.name)
//            coordinator.present(scene: .hashtagTimeline(viewModel: hashtagViewModel), from: self, transition: .show)
//        case .status:
//            aspectTableView(tableView, didSelectRowAt: indexPath)
//        case .bottomLoader:
//            break
//        }
//    }
//
//    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        aspectTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
//    }
//
//    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        aspectTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        aspectTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
//        aspectTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
//    }

}

// MARK: - UITableViewDataSourcePrefetching
//extension SearchResultViewController: UITableViewDataSourcePrefetching {
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        aspectTableView(tableView, cancelPrefetchingForRowsAt: indexPaths)
//    }
//
//    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
//        aspectTableView(tableView, cancelPrefetchingForRowsAt: indexPaths)
//    }
//}

// MARK: - AVPlayerViewControllerDelegate
//extension SearchResultViewController: AVPlayerViewControllerDelegate {
//    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
//    }
//
//    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
//    }
//}

// MARK: - StatusTableViewCellDelegate
extension SearchResultViewController: StatusTableViewCellDelegate { }
