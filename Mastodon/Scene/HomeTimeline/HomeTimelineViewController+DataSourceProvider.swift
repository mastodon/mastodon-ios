//
//  HomeTimelineViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import UIKit

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
        case .feed(let record):
            let managedObjectContext = context.managedObjectContext
            let item: DataSourceItem? = try? await managedObjectContext.perform {
                guard let feed = record.object(in: managedObjectContext) else { return nil }
                guard feed.kind == .home else { return nil }
                if let status = feed.status {
                    return .status(record: .init(objectID: status.objectID))
                } else {
                    return nil
                }
            }
            return item
        default:
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}
