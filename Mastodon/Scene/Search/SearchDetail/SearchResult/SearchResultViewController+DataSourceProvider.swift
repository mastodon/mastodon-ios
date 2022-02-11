//
//  SearchResultViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit

// MARK: - DataSourceProvider
extension SearchResultViewController: DataSourceProvider {
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
        case .user(let record):
            return .user(record: record)
        case .status(let record):
            return .status(record: record)
        case .hashtag(let entity):
            return .hashtag(tag: .entity(entity))
        default:
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

extension SearchResultViewController {
    func aspectTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): indexPath: \(indexPath.debugDescription)")
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: indexPath)
            guard let item = await item(from: source) else {
                return
            }
            
            await DataSourceFacade.responseToCreateSearchHistory(
                provider: self,
                item: item
            )
            
            switch item {
            case .status(let status):
                await DataSourceFacade.coordinateToStatusThreadScene(
                    provider: self,
                    target: .status,    // remove reblog wrapper
                    status: status
                )
            case .user(let user):
                await DataSourceFacade.coordinateToProfileScene(
                    provider: self,
                    user: user
                )
            case .hashtag(let tag):
                await DataSourceFacade.coordinateToHashtagScene(
                    provider: self,
                    tag: tag
                )
            case .notification:
                assertionFailure()
            }   // end switch
        }   // end Task
    }   // end func
}
