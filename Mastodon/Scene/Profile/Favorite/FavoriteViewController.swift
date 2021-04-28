//
//  FavoriteViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-6.
//

// Note: Prefer use US favorite then EN favourite in coding
// to following the text checker auto-correct behavior

import os.log
import UIKit
import AVKit
import Combine
import GameplayKit

final class FavoriteViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: FavoriteViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension FavoriteViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
        navigationItem.titleView = titleView
        titleView.update(title: L10n.Scene.Favorite.title, subtitle: nil)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.delegate = self
        tableView.prefetchDataSource = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            statusTableViewCellDelegate: self
        )
        
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

// MARK: - StatusTableViewControllerAspect
extension FavoriteViewController: StatusTableViewControllerAspect { }

// MARK: - TableViewCellHeightCacheableContainer
extension FavoriteViewController: TableViewCellHeightCacheableContainer {
    var cellFrameCache: NSCache<NSNumber, NSValue> {
        return viewModel.cellFrameCache
    }
}

// MARK: - UIScrollViewDelegate
extension FavoriteViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        aspectScrollViewDidScroll(scrollView)
    }
}

// MARK: - UITableViewDelegate
extension FavoriteViewController: UITableViewDelegate {

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
    
}

// MARK: - UITableViewDataSourcePrefetching
extension FavoriteViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        aspectTableView(tableView, prefetchRowsAt: indexPaths)
    }
}

// MARK: - AVPlayerViewControllerDelegate
extension FavoriteViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        aspectPlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        aspectPlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
}

// MARK: - TimelinePostTableViewCellDelegate
extension FavoriteViewController: StatusTableViewCellDelegate {
    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
    func parent() -> UIViewController { return self }
}

// MARK: - LoadMoreConfigurableTableViewContainer
extension FavoriteViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = FavoriteViewModel.State.Loading
    
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
}

