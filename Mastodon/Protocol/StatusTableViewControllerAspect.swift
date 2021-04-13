//
//  StatusTableViewControllerAspect.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-7.
//

import UIKit
import AVKit

//   Check List                     Last Updated
// - HomeViewController:                2021/4/13
// - FavoriteViewController:            2021/4/8
// - HashtagTimelineViewController:     2021/4/8
// - UserTimelineViewController:        2021/4/13
// - ThreadViewController:              2021/4/13
// * StatusTableViewControllerAspect:   2021/4/12

// (Fake) Aspect protocol to group common protocol extension implementations
// Needs update related view controller when aspect interface changes

/// Status related operations aspect
/// Please check the aspect methods (Option+Click) and add hook to implement features
/// - UI
/// - Media
/// - Data Source
protocol StatusTableViewControllerAspect: UIViewController {
    var tableView: UITableView { get }
}

// MARK: - UIViewController [A]

// [A1] aspectViewWillAppear(_:)
extension StatusTableViewControllerAspect {
    /// [UI] hook to deselect row in the transitioning for the table view
    func aspectViewWillAppear(_ animated: Bool) {
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
}

extension StatusTableViewControllerAspect where Self: NeedsDependency {
    /// [Media] hook to notify video service
    func aspectViewDidDisappear(_ animated: Bool) {
        context.videoPlaybackService.viewDidDisappear(from: self)
        context.audioPlaybackService.viewDidDisappear(from: self)
    }
}

// MARK: - UITableViewDelegate [B]

// [B1] aspectTableView(_:estimatedHeightForRowAt:)
extension StatusTableViewControllerAspect where Self: LoadMoreConfigurableTableViewContainer {
    /// [Data Source] hook to notify table view bottom loader
    func aspectScrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// [B2] aspectTableView(_:estimatedHeightForRowAt:)
extension StatusTableViewControllerAspect where Self: TableViewCellHeightCacheableContainer {
    /// [UI] hook to estimate  table view cell height from cache
    func aspectTableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        handleTableView(tableView, estimatedHeightForRowAt: indexPath)
    }
}

// [B3] aspectTableView(_:willDisplay:forRowAt:)
extension StatusTableViewControllerAspect where Self: StatusTableViewCellDelegate & StatusProvider {
    func aspectTableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        handleTableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
}

// [B4] aspectTableView(_:didEndDisplaying:forRowAt:)
extension StatusTableViewControllerAspect where Self: StatusTableViewCellDelegate & StatusProvider {
    /// [Media] hook to notify video service
    func aspectTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        handleTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
}

extension StatusTableViewControllerAspect where Self: TableViewCellHeightCacheableContainer & StatusProvider {
    /// [UI] hook to cache table view cell height
    func aspectTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cacheTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
}

extension StatusTableViewControllerAspect where Self: StatusTableViewCellDelegate & TableViewCellHeightCacheableContainer & StatusProvider {
    /// [Media] hook to notify video service
    /// [UI] hook to cache table view cell height
    func aspectTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        handleTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        cacheTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
}

// [B5] aspectTableView(_:didSelectRowAt:)
extension StatusTableViewControllerAspect where Self: StatusTableViewCellDelegate & StatusProvider {
    /// [UI] hook to coordinator to thread
    func aspectTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleTableView(tableView, didSelectRowAt: indexPath)
    }
}

// MARK: - UITableViewDataSourcePrefetching [C]

// [C1] aspectTableView(:prefetchRowsAt)
extension StatusTableViewControllerAspect where Self: UITableViewDataSourcePrefetching & StatusTableViewCellDelegate & StatusProvider {
    /// [Data Source] hook to prefetch reply to info for status
    func aspectTableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        handleTableView(tableView, prefetchRowsAt: indexPaths)
    }
}

// MARK: - AVPlayerViewControllerDelegate & NeedsDependency [D]

// [D1] aspectPlayerViewController(_:willBeginFullScreenPresentationWithAnimationCoordinator:)
extension StatusTableViewControllerAspect where Self: AVPlayerViewControllerDelegate & NeedsDependency {
    /// [Media] hook to mark transitioning to video service
    func aspectPlayerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
}

// [D2] aspectPlayerViewController(_:willEndFullScreenPresentationWithAnimationCoordinator:)
extension StatusTableViewControllerAspect where Self: AVPlayerViewControllerDelegate & NeedsDependency {
    /// [Media] hook to mark transitioning to video service
    func aspectPlayerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
}

