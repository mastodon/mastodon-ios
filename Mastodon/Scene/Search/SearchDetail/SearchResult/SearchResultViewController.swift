//
//  SearchResultViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import UIKit
import Combine
import CoreDataStack
import MastodonCore
import MastodonUI
import MastodonAsset

final class SearchResultViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    var viewModel: SearchResultViewModel!
    var disposeBag = Set<AnyCancellable>()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        return tableView
    }()

}

extension SearchResultViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self,
            userTableViewCellDelegate: self
        )
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.view.window != nil else { return }
                self.viewModel.stateMachine.enter(SearchResultViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)

        title = viewModel.searchText
        viewModel.listBatchFetchViewModel.shouldFetch.send()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.stateMachine.enter(SearchResultViewModel.State.Initial.self)
    }
}

// MARK: - StatusTableViewCellDelegate
extension SearchResultViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension SearchResultViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:SearchResultViewController.AutoGenerateTableViewDelegate

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
extension SearchResultViewController: StatusTableViewCellDelegate { }

// MARK: - UserTableViewCellDelegate
extension SearchResultViewController: UserTableViewCellDelegate {}
