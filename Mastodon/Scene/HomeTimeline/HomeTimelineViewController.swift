//
//  HomeTimelineViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import AlamofireImage

final class HomeTimelineViewController: UIViewController, NeedsDependency,TimelinePostTableViewCellDelegate {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = HomeTimelineViewModel(context: context)
    
    let avatarBarButtonItem = AvatarBarButtonItem()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        return tableView
    }()
    
    let refreshControl = UIRefreshControl()
    

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.HomeTimeline.title
        view.backgroundColor = Asset.Colors.Background.systemBackground.color
        navigationItem.leftBarButtonItem = avatarBarButtonItem
        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(HomeTimelineViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(HomeTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        viewModel.tableView = tableView
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            timelinePostTableViewCellDelegate: self,
            timelineMiddleLoaderTableViewCellDelegate: self
        )

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
        
        #if DEBUG
        avatarBarButtonItem.avatarButton.menu = debugMenu
        avatarBarButtonItem.avatarButton.showsMenuAsPrimaryAction = true
        #endif
        
        Publishers.CombineLatest(
            context.authenticationService.activeMastodonAuthentication.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] activeMastodonAuthentication, _ in
            guard let self = self else { return }
            guard let user = activeMastodonAuthentication?.user,
                  let avatarImageURL = user.avatarImageURL() else {
                let input = AvatarConfigurableViewConfiguration.Input(avatarImageURL: nil)
                self.avatarBarButtonItem.configure(withConfigurationInput: input)
                return
            }
            let input = AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL)
            self.avatarBarButtonItem.configure(withConfigurationInput: input)
        }
        .store(in: &disposeBag)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (self.viewModel.fetchedResultsController.fetchedObjects ?? []).count == 0 {
                self.viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.Loading.self)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            // fix AutoLayout cell height not update after rotate issue
            self.viewModel.cellFrameCache.removeAllObjects()
            self.tableView.reloadData()
        }
    }
}

extension HomeTimelineViewController {
    
    @objc private func avatarButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
    

}

// MARK: - UIScrollViewDelegate
extension HomeTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let cells = tableView.visibleCells.compactMap { $0 as? TimelineBottomLoaderTableViewCell }
        guard let loaderTableViewCell = cells.first else { return }
        
        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderTableViewCellFrameInWindow = tableView.convert(loaderTableViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderTableViewCellFrameInWindow.origin.y + 0.8 * loaderTableViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.loadoldestStateMachine.enter(HomeTimelineViewModel.LoadOldestState.Loading.self)
            }
        } else {
            viewModel.loadoldestStateMachine.enter(HomeTimelineViewModel.LoadOldestState.Loading.self)
        }
    }
}

// MARK: - UITableViewDelegate
extension HomeTimelineViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource else { return 100 }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return 100 }
        
        guard let frame = viewModel.cellFrameCache.object(forKey: NSNumber(value: item.hashValue))?.cgRectValue else {
            return 200
        }
        // os_log("%{public}s[%{public}ld], %{public}s: cache cell frame %s", ((#file as NSString).lastPathComponent), #line, #function, frame.debugDescription)

        return ceil(frame.height)
    }
}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate
extension HomeTimelineViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}


// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension HomeTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func configure(cell: TimelineMiddleLoaderTableViewCell, upperTimelineTootID: String?, timelineIndexobjectID: NSManagedObjectID?) {
        guard let upperTimelineIndexObjectID = timelineIndexobjectID else {
            return
        }
        viewModel.loadMiddleSateMachineList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self = self else { return }
                if let stateMachine = ids[upperTimelineIndexObjectID] {
                    guard let state = stateMachine.currentState else {
                        assertionFailure()
                        return
                    }

                    // make success state same as loading due to snapshot updating delay
                    let isLoading = state is HomeTimelineViewModel.LoadMiddleState.Loading || state is HomeTimelineViewModel.LoadMiddleState.Success
                    cell.loadMoreButton.isHidden = isLoading
                    if isLoading {
                        cell.activityIndicatorView.startAnimating()
                    } else {
                        cell.activityIndicatorView.stopAnimating()
                    }
                } else {
                    cell.loadMoreButton.isHidden = false
                    cell.activityIndicatorView.stopAnimating()
                }
            }
            .store(in: &cell.disposeBag)
        
        var dict = viewModel.loadMiddleSateMachineList.value
        if let _ = dict[upperTimelineIndexObjectID] {
            // do nothing
        } else {
            let stateMachine = GKStateMachine(states: [
                HomeTimelineViewModel.LoadMiddleState.Initial(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                HomeTimelineViewModel.LoadMiddleState.Loading(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                HomeTimelineViewModel.LoadMiddleState.Fail(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                HomeTimelineViewModel.LoadMiddleState.Success(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
            ])
            stateMachine.enter(HomeTimelineViewModel.LoadMiddleState.Initial.self)
            dict[upperTimelineIndexObjectID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict
        }
    }
    
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .homeMiddleLoader(let upper):
            guard let stateMachine = viewModel.loadMiddleSateMachineList.value[upper] else {
                assertionFailure()
                return
            }
            stateMachine.enter(HomeTimelineViewModel.LoadMiddleState.Loading.self)
        default:
            assertionFailure()
        }
    }
}

// MARK: - ScrollViewContainer
extension HomeTimelineViewController: ScrollViewContainer {
    
    var scrollView: UIScrollView { return tableView }
    
    func scrollToTop(animated: Bool) {
        if scrollView.contentOffset.y < scrollView.frame.height,
           viewModel.loadLatestStateMachine.canEnterState(HomeTimelineViewModel.LoadLatestState.Loading.self),
           (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) == 0.0,
           !refreshControl.isRefreshing {
            scrollView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: -refreshControl.frame.height), size: CGSize(width: 1, height: 1)), animated: animated)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.refreshControl.beginRefreshing()
                self.refreshControl.sendActions(for: .valueChanged)
            }
        } else {
            let indexPath = IndexPath(row: 0, section: 0)
            guard viewModel.diffableDataSource?.itemIdentifier(for: indexPath) != nil else { return }
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
}
