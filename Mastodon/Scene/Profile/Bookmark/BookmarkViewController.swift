//
//  BookmarkViewController.swift
//  Mastodon
//
//  Created by ProtoLimit on 2022-07-19.
//

import os.log
import UIKit
import AVKit
import Combine
import GameplayKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class BookmarkViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "BookmarkViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: BookmarkViewModel!
    
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
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension BookmarkViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)

        navigationItem.titleView = titleView
        titleView.update(title: L10n.Scene.Bookmark.title, subtitle: nil)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self
        )

        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(BookmarkViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        aspectViewDidDisappear(animated)
    }
    
}

// MARK: - UITableViewDelegate
extension BookmarkViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:BookmarkViewController.AutoGenerateTableViewDelegate

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
extension BookmarkViewController: StatusTableViewCellDelegate { }

// MARK: - AuthContextProvider
extension BookmarkViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

extension BookmarkViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}

// MARK: - StatusTableViewControllerNavigateable
extension BookmarkViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }
    
    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}
