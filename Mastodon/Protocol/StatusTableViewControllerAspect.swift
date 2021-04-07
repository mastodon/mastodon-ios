//
//  StatusTableViewControllerAspect.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-7.
//

import UIKit
import AVKit

protocol StatusTableViewControllerAspect: UIViewController {
    var tableView: UITableView { get }
}

// MARK: - UIViewController

// StatusTableViewControllerAspect.aspectViewWillAppear(_:)
extension StatusTableViewControllerAspect {
    func aspectViewWillAppear(_ animated: Bool) {
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
}

extension StatusTableViewControllerAspect where Self: NeedsDependency {
    func aspectViewDidDisappear(_ animated: Bool) {
        context.videoPlaybackService.viewDidDisappear(from: self)
    }
}

// MARK: - UITableViewDelegate

// aspectTableView(_:estimatedHeightForRowAt:)
extension StatusTableViewControllerAspect where Self: LoadMoreConfigurableTableViewContainer {
    func aspectScrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// aspectTableView(_:estimatedHeightForRowAt:)
extension StatusTableViewControllerAspect where Self: TableViewCellHeightCacheableContainer {
    func aspectTableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        handleTableView(tableView, estimatedHeightForRowAt: indexPath)
    }
}

// StatusTableViewControllerAspect.aspectTableView(_:didEndDisplaying:forRowAt:)
extension StatusTableViewControllerAspect where Self: StatusTableViewCellDelegate & StatusProvider {
    func aspectTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        handleTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
}

extension StatusTableViewControllerAspect where Self: TableViewCellHeightCacheableContainer & StatusProvider {
    func aspectTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        handleTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
}

extension StatusTableViewControllerAspect where Self: StatusTableViewCellDelegate & TableViewCellHeightCacheableContainer & StatusProvider {
    func aspectTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (self as StatusTableViewCellDelegate & StatusProvider).handleTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        (self as TableViewCellHeightCacheableContainer & StatusProvider).handleTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
}

// MARK: - AVPlayerViewControllerDelegate & NeedsDependency

// aspectPlayerViewController(_:willBeginFullScreenPresentationWithAnimationCoordinator:)
extension StatusTableViewControllerAspect where Self: AVPlayerViewControllerDelegate & NeedsDependency {
    func aspectPlayerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
}

// aspectPlayerViewController(_:willEndFullScreenPresentationWithAnimationCoordinator:)
extension StatusTableViewControllerAspect where Self: AVPlayerViewControllerDelegate & NeedsDependency {
    func aspectPlayerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
}

