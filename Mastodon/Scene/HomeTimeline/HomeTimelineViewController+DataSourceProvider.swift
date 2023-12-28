//
//  HomeTimelineViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import UIKit
import MastodonSDK

extension HomeTimelineViewController: DataSourceProvider {
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
        case .feed(let feed):
            guard feed.kind == .home else { return nil }
            if let status = feed.status {
                return .status(record: status)
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    func update(status: MastodonStatus) {
        viewModel.fetchedResultsController.update(status: status)
    }
    
    func delete(status: MastodonStatus) {
        viewModel.fetchedResultsController.records = viewModel.fetchedResultsController.records.filter { $0.id != status.id }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}
