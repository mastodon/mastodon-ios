//
//  ThreadViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import UIKit
import Combine
import CoreData
import AVKit
import MastodonMeta
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class ThreadViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "ThreadViewController", category: "ViewController")
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ThreadViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()
    
    let replyBarButtonItem = AdaptiveUserInterfaceStyleBarButtonItem(
        lightImage: UIImage(systemName: "arrowshape.turn.up.left")!,
        darkImage: UIImage(systemName: "arrowshape.turn.up.left.fill")!
    )
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(ThreadReplyLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: ThreadReplyLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ThreadViewController {
    
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
        
        navigationItem.title = L10n.Scene.Thread.backTitle
        navigationItem.titleView = titleView
        navigationItem.rightBarButtonItem = replyBarButtonItem
        replyBarButtonItem.button.addTarget(self, action: #selector(ThreadViewController.replyBarButtonItemPressed(_:)), for: .touchUpInside)
        
        viewModel.$navigationBarTitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                guard let self = self else { return }
                guard let title = title else {
                    self.titleView.update(title: "", subtitle: nil)
                    return
                }
                self.titleView.update(titleMetaContent: title, subtitle: nil)
            }
            .store(in: &disposeBag)
        
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIAccessibility.post(notification: .screenChanged, argument: tableView)
    }
    
}

extension ThreadViewController {
    @objc private func replyBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        guard case let .root(threadContext) = viewModel.root else { return }
        let composeViewModel = ComposeViewModel(
            context: context,
            authContext: viewModel.authContext,
            destination: .reply(parent: threadContext.status)
        )
        _ = coordinator.present(
            scene: .compose(viewModel: composeViewModel),
            from: self,
            transition: .modal(animated: true, completion: nil)
        )
    }
}

// MARK: - AuthContextProvider
extension ThreadViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension ThreadViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:ThreadViewController.AutoGenerateTableViewDelegate

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
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        
        switch item {
        case .thread(let thread):
            switch thread {
            case .root:
                return nil
            default:
                return indexPath
            }
        default:
            return indexPath
        }
    }
}


// MARK: - StatusTableViewCellDelegate
extension ThreadViewController: StatusTableViewCellDelegate { }

extension ThreadViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}

// MARK: - StatusTableViewControllerNavigateable
extension ThreadViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }

    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}
