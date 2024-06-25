//
//  SearchResultViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import MastodonSDK

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
        case .account(let account, let relationship):
            return .account(account: account, relationship: relationship)
        case .status(let record):
            return .status(record: record)
        case .hashtag(let tag):
            return .hashtag(tag: tag)
        default:
            return nil
        }
    }
    
    func update(status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        viewModel.dataController.update(status: status, intent: intent)
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

extension SearchResultViewController {
    func aspectTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
            case .account(let account, relationship: _):
                    await DataSourceFacade.coordinateToProfileScene(provider: self, account: account)
            case .status(let status):
                await DataSourceFacade.coordinateToStatusThreadScene(
                    provider: self,
                    target: .status,    // remove reblog wrapper
                    status: status
                )
            case .hashtag(let tag):
                await DataSourceFacade.coordinateToHashtagScene(
                    provider: self,
                    tag: tag
                )
            case .notification, .notificationBanner(_):
                assertionFailure()
            }   // end switch

            tableView.deselectRow(at: indexPath, animated: true)
        }   // end Task
    }   // end func
}
