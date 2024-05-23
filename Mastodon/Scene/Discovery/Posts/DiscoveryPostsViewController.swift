//
//  DiscoveryPostsViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import UIKit
import Combine
import MastodonCore
import MastodonUI

final class DiscoveryPostsViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: DiscoveryPostsViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    let refreshControl = RefreshControl()
    
    let discoveryIntroBannerView = DiscoveryIntroBannerView()
}

extension DiscoveryPostsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
        discoveryIntroBannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(discoveryIntroBannerView)
        NSLayoutConstraint.activate([
            discoveryIntroBannerView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            discoveryIntroBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            discoveryIntroBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        discoveryIntroBannerView.delegate = self
        discoveryIntroBannerView.isHidden = UserDefaults.shared.discoveryIntroBannerNeedsHidden
        UserDefaults.shared.publisher(for: \.discoveryIntroBannerNeedsHidden)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isHidden, on: discoveryIntroBannerView)
            .store(in: &disposeBag)

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self
        )
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(DiscoveryPostsViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        viewModel.didLoadLatest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refreshControl.endRefreshing()
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl.endRefreshing()
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

extension DiscoveryPostsViewController {
    
    @objc private func refreshControlValueChanged(_ sender: RefreshControl) {
        guard viewModel.stateMachine.enter(DiscoveryPostsViewModel.State.Reloading.self) else {
            sender.endRefreshing()
            return
        }
    }
    
}

// MARK: - AuthContextProvider
extension DiscoveryPostsViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension DiscoveryPostsViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:DiscoveryPostsViewController.AutoGenerateTableViewDelegate

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
extension DiscoveryPostsViewController: StatusTableViewCellDelegate { }

// MARK: ScrollViewContainer
extension DiscoveryPostsViewController: ScrollViewContainer {
    var scrollView: UIScrollView { tableView }
}

// MARK: - DiscoveryIntroBannerViewDelegate
extension DiscoveryPostsViewController: DiscoveryIntroBannerViewDelegate {
    func discoveryIntroBannerView(_ bannerView: DiscoveryIntroBannerView, closeButtonDidPressed button: UIButton) {
        UserDefaults.shared.discoveryIntroBannerNeedsHidden = true
    }
}

extension DiscoveryPostsViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}

// MARK: - StatusTableViewControllerNavigateable
extension DiscoveryPostsViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }

    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}

//MARK: - UIScrollViewDelegate

extension DiscoveryPostsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        ListBatchFetchViewModel.scrollViewdidScrollToEnd(scrollView) {
            viewModel.stateMachine.enter(DiscoveryPostsViewModel.State.Loading.self)
        }
    }
}
