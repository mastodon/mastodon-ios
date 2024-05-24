//
//  HashtagTimelineViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import UIKit
import AVKit
import Combine
import GameplayKit
import CoreData
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization
import MastodonSDK

final class HashtagTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    var disposeBag = Set<AnyCancellable>()
    var viewModel: HashtagTimelineViewModel!
    
    private lazy var headerView: HashtagTimelineHeaderView = {
        let headerView = HashtagTimelineHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: 118),
        ])

        return headerView
    }()
        
    let composeBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "square.and.pencil")!.withRenderingMode(.alwaysTemplate)
        return barButtonItem
    }()
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        return tableView
    }()
    
    let refreshControl = RefreshControl()
}

extension HashtagTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _title = "#\(viewModel.hashtag)"
        title = _title
        titleView.update(title: _title, subtitle: nil)
        navigationItem.titleView = titleView

        view.backgroundColor = .secondarySystemBackground
        
        navigationItem.rightBarButtonItem = composeBarButtonItem
        composeBarButtonItem.target = self
        composeBarButtonItem.action = #selector(HashtagTimelineViewController.composeBarButtonItemPressed(_:))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self
        )
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(HashtagTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        viewModel.didLoadLatest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refreshControl.endRefreshing()
            }
            .store(in: &disposeBag)

        viewModel.hashtagEntity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tag in
                self?.updatePromptTitle()
            }
            .store(in: &disposeBag)
        
        viewModel.hashtagDetails
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tag in
                guard let tag = tag else { return }
                self?.updateHeaderView(with: tag)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.viewWillAppear()
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

extension HashtagTimelineViewController {
    
    private func updatePromptTitle() {
        var subtitle: String?
        defer {
            titleView.update(title: "#" + viewModel.hashtag, subtitle: subtitle)
        }
        guard let histories = viewModel.hashtagEntity.value?.history else {
            return
        }
        if histories.isEmpty {
            // No tag history, remove the prompt title
            return
        } else {
            let sortedHistory = histories.sorted { (h1, h2) -> Bool in
                return h1.day > h2.day
            }
            let peopleTalkingNumber = sortedHistory
                .prefix(2)
                .compactMap({ Int($0.accounts) })
                .reduce(0, +)
            subtitle = L10n.Plural.peopleTalking(peopleTalkingNumber)
        }
    }
}

extension HashtagTimelineViewController {
    private func updateHeaderView(with tag: Mastodon.Entity.Tag) {
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = headerView
        }
        headerView.update(HashtagTimelineHeaderView.Data.from(tag))
        headerView.onButtonTapped = { [weak self] in
            switch tag.following {
            case .some(false):
                self?.viewModel.followTag()
            case .some(true):
                self?.viewModel.unfollowTag()
            default:
                break
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerView.updateWidthConstraint(tableView.bounds.width)
    }
}

extension HashtagTimelineViewController {
    
    @objc private func refreshControlValueChanged(_ sender: RefreshControl) {
        guard viewModel.stateMachine.enter(HashtagTimelineViewModel.State.Reloading.self) else {
            sender.endRefreshing()
            return
        }
    }
    
    @objc private func composeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let hashtag = "#" + viewModel.hashtag
        UITextChecker.learnWord(hashtag)
        let composeViewModel = ComposeViewModel(
            context: context,
            authContext: viewModel.authContext,
            composeContext: .composeStatus,
            destination: .topLevel,
            initialContent: hashtag
        )
        _ = coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }

}

// MARK: - AuthContextProvider
extension HashtagTimelineViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension HashtagTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:HashtagTimelineViewController.AutoGenerateTableViewDelegate

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
    
}

// MARK: - StatusTableViewCellDelegate
extension HashtagTimelineViewController: StatusTableViewCellDelegate { }

extension HashtagTimelineViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}
// MARK: - StatusTableViewControllerNavigateable
extension HashtagTimelineViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }
    
    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}

// MARK: - UIScrollViewDelegate

extension HashtagTimelineViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        ListBatchFetchViewModel.scrollViewDidScrollToEnd(scrollView) {
            viewModel.stateMachine.enter(HashtagTimelineViewModel.State.Loading.self)
        }
    }
}
