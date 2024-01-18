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
    
    func update(status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        switch viewModel.root {
        case let .root(context):
            if context.status.id == status.id {
                viewModel.root = .root(context: .init(status: status))
            } else {
                handle(status: status)
            }
        case let .reply(context):
            if context.status.id == status.id {
                viewModel.root = .reply(context: .init(status: status))
            } else {
                handle(status: status)
            }
        case let .leaf(context):
            if context.status.id == status.id {
                viewModel.root = .leaf(context: .init(status: status))
            } else {
                handle(status: status)
            }
        case .none:
            assertionFailure("This should not have happened")
        }
    }
    
    private func handle(status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        if case MastodonStatus.UpdateIntent.delete = intent {
            delete(status: status)
        } else {
            handle(status: status)
        }
    }
    
    private func handle(status: MastodonStatus) {
        viewModel.mastodonStatusThreadViewModel.ancestors.handleUpdate(status: status, for: viewModel)
        viewModel.mastodonStatusThreadViewModel.descendants.handleUpdate(status: status, for: viewModel)
    }
    
    private func delete(status: MastodonStatus) {
        if viewModel.root?.record.id == status.id {
            viewModel.root = nil
            viewModel.onDismiss.send(status)
        }
        viewModel.mastodonStatusThreadViewModel.ancestors.handleDelete(status: status, for: viewModel)
        viewModel.mastodonStatusThreadViewModel.descendants.handleDelete(status: status, for: viewModel)
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

private extension [StatusItem] {
    mutating func handleUpdate(status: MastodonStatus, for viewModel: ThreadViewModel) {
        for (index, ancestor) in enumerated() {
            switch ancestor {
            case let .feed(record):
                if record.status?.id == status.id {
                    self[index] = .feed(record: .fromStatus(status, kind: record.kind))
                }
            case let.feedLoader(record):
                if record.status?.id == status.id {
                    self[index] = .feedLoader(record: .fromStatus(status, kind: record.kind))
                }
            case let .status(record):
                if record.id == status.id {
                    self[index] = .status(record: status)
                }
            case let .thread(thread):
                switch thread {
                case let .root(context):
                    if context.status.id == status.id {
                        self[index] = .thread(.root(context: .init(status: status)))
                    }
                case let .reply(context):
                    if context.status.id == status.id {
                        self[index] = .thread(.reply(context: .init(status: status)))
                    }
                case let .leaf(context):
                    if context.status.id == status.id {
                        self[index] = .thread(.leaf(context: .init(status: status)))
                    }
                }
            case .bottomLoader, .topLoader:
                break
            }
        }
    }
    
    mutating func handleDelete(status: MastodonStatus, for viewModel: ThreadViewModel) {
        for (index, ancestor) in enumerated() {
            switch ancestor {
            case let .feed(record):
                if record.status?.id == status.id {
                    self.remove(at: index)
                }
            case let.feedLoader(record):
                if record.status?.id == status.id {
                    self.remove(at: index)
                }
            case let .status(record):
                if record.id == status.id {
                    self.remove(at: index)
                }
            case let .thread(thread):
                switch thread {
                case let .root(context):
                    if context.status.id == status.id {
                        self.remove(at: index)
                    }
                case let .reply(context):
                    if context.status.id == status.id {
                        self.remove(at: index)
                    }
                case let .leaf(context):
                    if context.status.id == status.id {
                        self.remove(at: index)
                    }
                }
            case .bottomLoader, .topLoader:
                break
            }
        }
    }
}
