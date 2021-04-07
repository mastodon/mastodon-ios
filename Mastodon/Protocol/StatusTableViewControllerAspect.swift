//
//  StatusTableViewControllerAspect.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-7.
//

import UIKit
import AVKit

/// Status related operations aspect
/// Please check the aspect methods (Option+Click) and add hook to implement features
/// - UI
/// - Media
/// - Data Source
protocol StatusTableViewControllerAspect: UIViewController {
    var tableView: UITableView { get }
}

// MARK: - UIViewController

// aspectViewWillAppear(_:)
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
    }
}

// MARK: - UITableViewDelegate

// aspectTableView(_:estimatedHeightForRowAt:)
extension StatusTableViewControllerAspect where Self: LoadMoreConfigurableTableViewContainer {
    /// [Data Source] hook to notify table view bottom loader
    func aspectScrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// aspectTableView(_:estimatedHeightForRowAt:)
extension StatusTableViewControllerAspect where Self: TableViewCellHeightCacheableContainer {
    /// [UI] hook to estimate  table view cell height from cache
    func aspectTableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        handleTableView(tableView, estimatedHeightForRowAt: indexPath)
    }
}

// StatusTableViewControllerAspect.aspectTableView(_:didEndDisplaying:forRowAt:)
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

// MARK: - AVPlayerViewControllerDelegate & NeedsDependency

// aspectPlayerViewController(_:willBeginFullScreenPresentationWithAnimationCoordinator:)
extension StatusTableViewControllerAspect where Self: AVPlayerViewControllerDelegate & NeedsDependency {
    /// [Media] hook to mark transitioning to video service
    func aspectPlayerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
}

// aspectPlayerViewController(_:willEndFullScreenPresentationWithAnimationCoordinator:)
extension StatusTableViewControllerAspect where Self: AVPlayerViewControllerDelegate & NeedsDependency {
    /// [Media] hook to mark transitioning to video service
    func aspectPlayerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
}

