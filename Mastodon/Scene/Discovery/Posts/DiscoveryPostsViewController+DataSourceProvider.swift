//
//  DiscoveryPostsViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import UIKit
import MastodonSDK

extension DiscoveryPostsViewController: DataSourceProvider {
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
        case .status(let record):
            return .status(record: record)
        default:
            return nil
        }
    }

    func update(status: MastodonStatus) {
        viewModel.dataController.update(status: status)
    }
    
    func delete(status: MastodonStatus) {
        viewModel.dataController.setRecords(
            viewModel.dataController.records.filter { $0.id != status.id }
        )
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}
