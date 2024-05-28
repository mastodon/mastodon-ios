//
//  FollowingListViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-2.
//

import UIKit
import GameplayKit
import Combine
import MastodonLocalization
import MastodonCore
import MastodonUI
import CoreDataStack
import MastodonSDK

final class FollowingListViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: FollowingListViewModel

    let refreshControl: UIRefreshControl
    let tableView: UITableView

    init(viewModel: FollowingListViewModel, coordinator: SceneCoordinator, context: AppContext) {

        self.context = context
        self.coordinator = coordinator
        self.viewModel = viewModel

        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TimelineFooterTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineFooterTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl

        super.init(nibName: nil, bundle: nil)

        title = L10n.Scene.Following.title

        view.backgroundColor = .secondarySystemBackground

        view.addSubview(tableView)
        tableView.pinToParent()
        tableView.delegate = self
        tableView.refreshControl?.addTarget(self, action: #selector(FollowingListViewController.refresh(_:)), for: .valueChanged)

        viewModel.tableView = tableView

        refreshControl.addTarget(self, action: #selector(FollowingListViewController.refresh(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.setupDiffableDataSource(
            tableView: tableView,
            userTableViewCellDelegate: self
        )

        // setup batch fetch
        viewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.viewModel.stateMachine.enter(FollowingListViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        // trigger user timeline loading
        Publishers.CombineLatest(
            viewModel.$domain.removeDuplicates(),
            viewModel.$userID.removeDuplicates()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.stateMachine.enter(FollowingListViewModel.State.Reloading.self)
        }
        .store(in: &disposeBag)

        tableView.refreshControl = UIRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }

    //MARK: - Actions

    @objc
    func refresh(_ sender: UIRefreshControl) {
        viewModel.stateMachine.enter(FollowingListViewModel.State.Reloading.self)
    }
}

// MARK: - AuthContextProvider
extension FollowingListViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension FollowingListViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:FollowingListViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    // sourcery:end
}

// MARK: - UserTableViewCellDelegate
extension FollowingListViewController: UserTableViewCellDelegate {}


// MARK: - DataSourceProvider
extension FollowingListViewController: DataSourceProvider {
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        var _indexPath = source.indexPath
        if _indexPath == nil, let cell = source.tableViewCell {
            _indexPath = await self.indexPath(for: cell)
        }
        guard let indexPath = _indexPath else { return nil }

        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }

        switch item {
            case .account(let account, let relationship):
                return .account(account: account, relationship: relationship)
            default:
                return nil
        }
    }
    
    func update(status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        assertionFailure("Not required")
    }

    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

//MARK: - UIScrollViewDelegate

extension FollowingListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Self.scrollViewDidScrollToEnd(scrollView) {
            viewModel.shouldFetch.send()
        }
    }
}

