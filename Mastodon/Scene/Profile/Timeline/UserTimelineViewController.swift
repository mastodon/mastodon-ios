//
//  UserTimelineViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import UIKit
import AVKit
import Combine
import CoreDataStack
import GameplayKit
import TabBarPager
import XLPagerTabStrip
import MastodonCore

final class UserTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserTimelineViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
        
    let cellFrameCache = NSCache<NSNumber, NSValue>()

    
}

extension UserTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - CellFrameCacheContainer
extension UserTimelineViewController: CellFrameCacheContainer {
    func keyForCache(tableView: UITableView, indexPath: IndexPath) -> NSNumber? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        let key = NSNumber(value: item.hashValue)
        return key
    }
}

// MARK: - AuthContextProvider
extension UserTimelineViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

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
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let frame = retrieveCellFrame(tableView: tableView, indexPath: indexPath) else {
            return 200
        }
        return ceil(frame.height)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cacheCellFrame(tableView: tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
    
}

// MARK: - CustomScrollViewContainerController
extension UserTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return tableView }
}

// MARK: - TabBarPage
extension UserTimelineViewController: TabBarPage {
    var pageScrollView: UIScrollView {
        scrollView
    }
}

// MARK: - StatusTableViewCellDelegate
extension UserTimelineViewController: StatusTableViewCellDelegate { }

extension UserTimelineViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}

// MARK: - StatusTableViewControllerNavigateable
extension UserTimelineViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }
    
    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}

// MARK: - IndicatorInfoProvider
extension UserTimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: viewModel.title)
    }
}

//MARK: - UIScrollViewDelegate
extension UserTimelineViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        ListBatchFetchViewModel.scrollViewDidScrollToEnd(scrollView) {
            viewModel.stateMachine.enter(UserTimelineViewModel.State.Loading.self)
        }
    }
}
