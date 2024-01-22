//
//  ThreadViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import MastodonSDK

// MARK: - DataSourceProvider
extension ThreadViewController: DataSourceProvider {
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
        case .thread(let thread):
            return .status(record: thread.record)
        default:
            return nil
        }
    }
    
    func update(status _status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        let status = _status.reblog ?? _status
        if case MastodonStatus.UpdateIntent.delete = intent {
            return handleDelete(status)
        }
        
        switch viewModel.root {
        case let .root(context):
            if context.status.id == status.id {
                viewModel.root = .root(context: .init(status: status))
            } else {
                handleUpdate(status: status, viewModel: viewModel.mastodonStatusThreadViewModel, intent: intent)
            }
        case let .reply(context):
            if context.status.id == status.id {
                viewModel.root = .reply(context: .init(status: status))
            } else {
                handleUpdate(status: status, viewModel: viewModel.mastodonStatusThreadViewModel, intent: intent)
            }
        case let .leaf(context):
            if context.status.id == status.id {
                viewModel.root = .leaf(context: .init(status: status))
            } else {
                handleUpdate(status: status, viewModel: viewModel.mastodonStatusThreadViewModel, intent: intent)
            }
        case .none:
            assertionFailure("This should not have happened")
        }
    }

    private func handleDelete(_ status: MastodonStatus) {
        if viewModel.root?.record.id == status.id {
            viewModel.root = nil
            viewModel.onDismiss.send(status)
        }
        viewModel.mastodonStatusThreadViewModel.handleDelete(status)
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
    
    private func handleUpdate(status: MastodonStatus, viewModel: MastodonStatusThreadViewModel, intent: MastodonStatus.UpdateIntent) {
        switch intent {
        case .bookmark:
            viewModel.handleBookmark(status)
        case let .reblog(isReblogged):
            viewModel.handleReblog(status, isReblogged)
        case .favorite:
            viewModel.handleFavorite(status)
        case let .toggleSensitive(isVisible):
            viewModel.handleSensitive(status, isVisible)
        case .edit:
            viewModel.handleEdit(status)
        case .delete:
            break // this case has already been handled
        }
    }
}
