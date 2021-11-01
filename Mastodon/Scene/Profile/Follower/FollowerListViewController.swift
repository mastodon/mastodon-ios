//
//  FollowerListViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import os.log
import UIKit
import AVKit
import GameplayKit
import Combine

final class FollowerListViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: FollowerListViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TimelineFooterTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineFooterTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
 
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension FollowerListViewController {
    
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
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self
        )
        // TODO: add UserTableViewCellDelegate        
        
        // trigger user timeline loading
        Publishers.CombineLatest(
            viewModel.domain.removeDuplicates().eraseToAnyPublisher(),
            viewModel.userID.removeDuplicates().eraseToAnyPublisher()
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(FollowerListViewModel.State.Reloading.self)
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - LoadMoreConfigurableTableViewContainer
extension FollowerListViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = FollowerListViewModel.State.Loading
    var loadMoreConfigurableTableView: UITableView { tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { viewModel.stateMachine }
}

// MARK: - UIScrollViewDelegate
extension FollowerListViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}


// MARK: - UITableViewDelegate
extension FollowerListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleTableView(tableView, didSelectRowAt: indexPath)
    }
}

// MARK: - UserTableViewCellDelegate
extension FollowerListViewController: UserTableViewCellDelegate { }
