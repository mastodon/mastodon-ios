//
//  ThreadViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit

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
            assertionFailure()
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}
