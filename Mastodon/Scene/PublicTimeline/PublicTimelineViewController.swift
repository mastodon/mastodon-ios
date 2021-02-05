//
//  PublicTimelineViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import AVKit
import Combine
import CoreDataStack
import GameplayKit
import os.log
import UIKit

final class PublicTimelineViewController: UIViewController, NeedsDependency, TimelinePostTableViewCellDelegate {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: PublicTimelineViewModel!
    
    let refreshControl = UIRefreshControl()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
    }
}

extension PublicTimelineViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Asset.Colors.Background.systemBackground.color
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(PublicTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
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
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.tableView = tableView
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            timelinePostTableViewCellDelegate: self
        )
    }

}

// MARK: - UIScrollViewDelegate
extension PublicTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// MARK: - Selector
extension PublicTimelineViewController {
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.stateMachine.enter(PublicTimelineViewModel.State.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
}

// MARK: - UITableViewDelegate
extension PublicTimelineViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource else { return 100 }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return 100 }
        
        guard let frame = viewModel.cellFrameCache.object(forKey: NSNumber(value: item.hashValue))?.cgRectValue else {
            return 200
        }
        
        return ceil(frame.height)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        let key = item.hashValue
        let frame = cell.frame
        viewModel.cellFrameCache.setObject(NSValue(cgRect: frame), forKey: NSNumber(value: key))
    }
}
// MARK: - LoadMoreConfigurableTableViewContainer
extension PublicTimelineViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = PublicTimelineViewModel.State.LoadingMore
    
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
}
